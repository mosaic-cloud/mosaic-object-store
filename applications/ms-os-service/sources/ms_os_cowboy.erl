%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-module (ms_os_cowboy).


-export ([
		start_link/2,
		init/3, terminate/3, handle/2]).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-ve_cowboy_route ({any, [<<"v1">>, <<"status">>], status}).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


start_link (QualifiedName, ConfigurationSpecification) ->
	case configuration (ConfigurationSpecification) of
		{ok, Configuration} ->
			ve_cowboy:start_link (QualifiedName, Configuration);
		Error = {error, _} ->
			Error
	end.


%----------------------------------------------------------------------------


configuration (defaults) ->
	Protocol = http,
	Port = 8080,
	Targets = [
			{module, ms_os_cowboy},
			{module, ms_os_rest}
	],
	{ok, {Protocol, Port, Targets}};
	
configuration (Configuration) ->
	{error, {invalid_configuration, Configuration}}.


%----------------------------------------------------------------------------


init (_Connection, Request, status) ->
	{ok, Request, status}.

terminate (_Reason, _Request, _State) ->
	ok.

handle (Request, status) ->
	ve_cowboy:reply_outcome (json, ok, Request, none).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------
