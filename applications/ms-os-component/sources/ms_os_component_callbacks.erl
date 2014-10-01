
-module (ms_os_component_callbacks).

-behaviour (mosaic_component_callbacks).


-export ([configure/0, standalone/0]).
-export ([init/0, terminate/2, handle_call/5, handle_cast/4, handle_info/2]).


-import (mosaic_enforcements, [enforce_ok/1, enforce_ok_1/1, enforce_ok_2/1]).


-record (state, {status, identifier, group, service_socket}).


init () ->
	try
		State = #state{
					status = waiting_initialize,
					identifier = none, group = none,
					service_socket = none},
		erlang:self () ! {ms_os_component_callbacks_internals, trigger_initialize},
		{ok, State}
	catch throw : {error, Reason} -> {stop, Reason} end.


terminate (_Reason, _State = #state{}) ->
	ok = stop_applications_async (),
	ok.


handle_call (<<"mosaic-object-store:get-service-endpoint">>, null, <<>>, _Sender, State = #state{status = executing, service_socket = Socket}) ->
	{SocketIp, SocketPort, SocketFqdn} = Socket,
	Outcome = {ok, {struct, [
					{<<"ip">>, SocketIp}, {<<"port">>, SocketPort}, {<<"fqdn">>, SocketFqdn},
					{<<"url">>, erlang:iolist_to_binary (["http://", SocketFqdn, ":", erlang:integer_to_list (SocketPort), "/"])}
				]}, <<>>},
	{reply, Outcome, State};
	
handle_call (<<"mosaic-object-store:get-node-identifier">>, null, <<>>, _Sender, State) ->
	Outcome = {ok, erlang:atom_to_binary (erlang:node (), utf8), <<>>},
	{reply, Outcome, State};
	
handle_call (Operation, Inputs, _Data, _Sender, State = #state{status = executing}) ->
	ok = mosaic_transcript:trace_error ("received invalid call request; ignoring!", [{operation, Operation}, {inputs, Inputs}]),
	{reply, {error, {invalid_operation, Operation}}, State};
	
handle_call (Operation, Inputs, _Data, _Sender, State = #state{status = Status})
		when (Status =/= executing) ->
	ok = mosaic_transcript:trace_error ("received invalid call request; ignoring!", [{operation, Operation}, {inputs, Inputs}, {status, Status}]),
	{reply, {error, {invalid_status, Status}}, State}.


handle_cast (Operation, Inputs, _Data, State = #state{status = executing}) ->
	ok = mosaic_transcript:trace_error ("received invalid cast request; ignoring!", [{operation, Operation}, {inputs, Inputs}]),
	{noreply, State};
	
handle_cast (Operation, Inputs, _Data, State = #state{status = Status})
		when (Status =/= executing) ->
	ok = mosaic_transcript:trace_error ("received invalid cast request; ignoring!", [{operation, Operation}, {inputs, Inputs}, {status, Status}]),
	{noreply, State}.


handle_info ({ms_os_component_callbacks_internals, trigger_initialize}, OldState = #state{status = waiting_initialize}) ->
	try
		Identifier = enforce_ok_1 (mosaic_generic_coders:application_env_get (identifier, ms_os_component,
					{decode, fun mosaic_component_coders:decode_component/1}, {error, missing_identifier})),
		Group = enforce_ok_1 (mosaic_generic_coders:application_env_get (group, ms_os_component,
					{decode, fun mosaic_component_coders:decode_group/1}, {error, missing_group})),
		ok = enforce_ok (mosaic_component_callbacks:acquire_async (
					[{<<"service_socket">>, <<"socket:ipv4:tcp">>}],
					{ms_os_component_callbacks_internals, acquire_return})),
		NewState = OldState#state{status = waiting_acquire_return, identifier = Identifier, group = Group},
		{noreply, NewState}
	catch throw : Error = {error, _Reason} -> {stop, Error, OldState} end;
	
handle_info ({{ms_os_component_callbacks_internals, acquire_return}, Outcome}, OldState = #state{status = waiting_acquire_return, identifier = Identifier, group = Group}) ->
	try
		Descriptors = enforce_ok_1 (Outcome),
		[ServiceSocket] = enforce_ok_1 (mosaic_component_coders:decode_socket_ipv4_tcp_descriptors (
					[<<"service_socket">>], Descriptors)),
		NewState = OldState#state{status = waiting_resolve_return, service_socket = ServiceSocket},
		ok = enforce_ok (setup_applications (Identifier, ServiceSocket)),
		ok = enforce_ok (start_applications ()),
		ok = enforce_ok (mosaic_component_callbacks:register_async (Group, {ms_os_component_callbacks_internals, register_return})),
		NewState = OldState#state{status = waiting_register_return},
		{noreply, NewState}
	catch throw : Error = {error, _Reason} -> {stop, Error, OldState} end;
	
handle_info ({{ms_os_component_callbacks_internals, register_return}, Outcome}, OldState = #state{status = waiting_register_return}) ->
	try
		ok = enforce_ok (Outcome),
		NewState = OldState#state{status = executing},
		{noreply, NewState}
	catch throw : Error = {error, _Reason} -> {stop, Error, OldState} end;
	
handle_info (Message, State = #state{status = Status}) ->
	ok = mosaic_transcript:trace_error ("received invalid message; terminating!", [{message, Message}, {status, Status}]),
	{stop, {error, {invalid_message, Message}}, State}.


standalone () ->
	mosaic_application_tools:boot (fun standalone_1/0).

standalone_1 () ->
	try
		ok = enforce_ok (load_applications ()),
		ok = enforce_ok (mosaic_component_callbacks:configure ([{identifier, ms_os_component}])),
		Identifier = enforce_ok_1 (mosaic_generic_coders:application_env_get (identifier, ms_os_component,
					{decode, fun mosaic_component_coders:decode_component/1}, {error, missing_identifier})),
		ServiceSocket = {<<"0.0.0.0">>, 20622, <<"127.0.0.1">>},
		ok = enforce_ok (setup_applications (Identifier, ServiceSocket)),
		ok
	catch throw : Error = {error, _Reason} -> Error end.


configure () ->
	try
		ok = enforce_ok (load_applications ()),
		ok = enforce_ok (mosaic_component_callbacks:configure ([
					{identifier, ms_os_component},
					{group, ms_os_component},
					harness])),
		ok
	catch throw : Error = {error, _Reason} -> Error end.


load_applications () ->
	try
		ok = enforce_ok (mosaic_application_tools:load ([ms_os_component, ms_os_service], with_dependencies)),
		ok
	catch throw : Error = {error, _Reason} -> Error end.


setup_applications (Identifier, ServiceSocket) ->
	try
		IdentifierString = enforce_ok_1 (mosaic_component_coders:encode_component (Identifier)),
		{ServiceSocketIp, ServiceSocketPort, ServiceSocketFqdn} = ServiceSocket,
		ServiceSocketIpString = erlang:binary_to_list (ServiceSocketIp),
		ServiceSocketFqdnString = erlang:binary_to_list (ServiceSocketFqdn),
		ok = enforce_ok (mosaic_component_callbacks:configure ([
					{env, ms_os_service, service_ip, ServiceSocketIpString},
					{env, ms_os_service, service_port, ServiceSocketPort}])),
		ok = error_logger:info_report (["Configuring mOSAIC object store component...",
					{identifier, IdentifierString},
					{url, erlang:list_to_binary ("http://" ++ ServiceSocketFqdnString ++ ":" ++ erlang:integer_to_list (ServiceSocketPort) ++ "/")},
					{service_endpoint, ServiceSocket}]),
		ok
	catch throw : Error = {error, _Reason} -> Error end.


start_applications () ->
	try
		ok = enforce_ok (mosaic_application_tools:start (ms_os_service, with_dependencies)),
		ok
	catch throw : Error = {error, _Reason} -> Error end.


stop_applications () ->
	_ = init:stop ().


stop_applications_async () ->
	_ = erlang:spawn (
				fun () ->
					ok = timer:sleep (100),
					ok = stop_applications (),
					ok
				end),
	ok.
