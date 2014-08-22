%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-module (ms_os_backend).


-export ([
		start_link/2, call/2, call/3]).

-export ([
		init/1, terminate/2, code_change/3,
		handle_call/3, handle_cast/2, handle_info/2]).


-import (ve_enforcements, [enforce_ok_1/1, enforce_ok_map/2]).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


start_link (QualifiedName, ConfigurationSpecification) ->
	case configuration (ConfigurationSpecification) of
		{ok, Configuration} ->
			ve_process_tools:start_link (gen_server, ms_os_backend, QualifiedName, Configuration);
		Error = {error, _} ->
			Error
	end.


%----------------------------------------------------------------------------


call (Operation, Arguments) ->
	call (ms_os_backend, Operation, Arguments).

call (Process, Operation, Arguments) ->
	ve_gen_tools:call (gen_server, Process, ms_os_backend, Operation, Arguments).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-include ("ms_os_coders.hrl").


-record (state, {
		objects}).


%----------------------------------------------------------------------------


configuration (defaults) ->
	{ok, defaults};
	
configuration (Configuration) ->
	{error, {invalid_configuration, Configuration}}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


handle_object_create (Object = #ms_os_object_v1{key = Key}, _Callback, State) ->
	case gb_trees:is_defined (Key, State#state.objects) of
		false ->
			case ms_os_coders:merge_object (Object, none) of
				{ok, MergedObject} ->
					Objects_2 = gb_trees:insert (Key, MergedObject, State#state.objects),
					{reply, ok, State#state{objects = Objects_2}};
				Error = {error, _} ->
					{reply, Error, State}
			end;
		true ->
			{reply, {error, exists}, State}
	end.


handle_object_destroy (Key = #ms_os_object_key_v1{}, _Callback, State) ->
	case gb_trees:is_defined (Key, State#state.objects) of
		true ->
			Objects_2 = gb_trees:delete (Key, State#state.objects),
			{reply, ok, State#state{objects = Objects_2}};
		false ->
			{reply, {error, missing}, State}
	end.


handle_object_select (Key = #ms_os_object_key_v1{}, _Callback, State) ->
	case gb_trees:lookup (Key, State#state.objects) of
		{value, Object} ->
			{reply, {ok, Object}, State};
		none ->
			{reply, {error, missing}, State}
	end.


handle_object_update (NewObject = #ms_os_object_v1{key = Key}, _Callback, State) ->
	case gb_trees:lookup (Key, State#state.objects) of
		{value, OldObject} ->
			case ms_os_coders:merge_object (NewObject, OldObject) of
				{ok, MergedObject} ->
					Objects_2 = gb_trees:update (Key, MergedObject, State#state.objects),
					{reply, ok, State#state{objects = Objects_2}};
				Error = {error, _} ->
					{reply, Error, State}
			end;
		none ->
			{reply, {error, missing}, State}
	end.


handle_object_patch ({Key, Patch}, _Callback, State) ->
	case gb_trees:lookup (Key, State#state.objects) of
		{value, OldObject} ->
			case ms_os_coders:patch_object (Patch, OldObject) of
				{ok, PatchedObject} ->
					Objects_2 = gb_trees:update (Key, PatchedObject, State#state.objects),
					{reply, ok, State#state{objects = Objects_2}};
				Error = {error, _} ->
					{reply, Error, State}
			end;
		none ->
			{reply, {error, missing}, State}
	end.


handle_objects_select ({Selector, Mangler}, _Callback, State) ->
	try
		Objects = lists:filtermap (
				fun (Object) ->
					case enforce_ok_1 (ms_os_coders:match_object (Selector, Object)) of
						true ->
							{true, enforce_ok_1 (ms_os_coders:mangle_object (Mangler, Object))};
						false ->
							false
					end
				end,
				gb_trees:values (State#state.objects)),
		{reply, {ok, Objects}, State}
	catch throw : Error = {error, _} ->
		{reply, Error, State}
	end.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


init ({_QualifiedName, defaults}) ->
	Objects = gb_trees:empty (),
	State = #state{objects = Objects},
	{ok, State}.


terminate (_Reason, _State) ->
	ok.


handle_call (Request, Callback, State) ->
	ve_gen_tools:handle_dispatch_call (Request, Callback, fun handle_call_dispatcher/2, State).

handle_cast (Request, State) ->
	ve_gen_tools:handle_dispatch_cast (Request, fun handle_cast_dispatcher/2, State).

handle_info (Message, State) ->
	ve_gen_tools:handle_invalid_info (Message, State).

code_change (_OldVersion, State, _Arguments) ->
	{ok, State}.


%----------------------------------------------------------------------------


handle_call_dispatcher (ms_os_backend, Operation) ->
	case Operation of
		object_create ->
			{fun handle_object_create/3, fun ms_os_coders:validate_object/1};
		object_destroy ->
			{fun handle_object_destroy/3, fun ms_os_coders:validate_object_key/1};
		object_select ->
			{fun handle_object_select/3, fun ms_os_coders:validate_object_key/1};
		object_update ->
			{fun handle_object_update/3, fun ms_os_coders:validate_object/1};
		object_patch ->
			{fun handle_object_patch/3, fun ms_os_coders:validate_object_patch/1};
		objects_select ->
			{fun handle_objects_select/3,
					fun (Arguments) ->
						ve_generic_coders:validate_term (Arguments,
								{tuple, {
										{schema, fun ms_os_coders:schema_term/1, object_selector},
										{schema, fun ms_os_coders:schema_term/1, object_mangler}}})
					end};
		_ ->
			undefined
	end;
	
handle_call_dispatcher (_Interface, _Operation) ->
	undefined.


handle_cast_dispatcher (_Interface, _Operation) ->
	undefined.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------
