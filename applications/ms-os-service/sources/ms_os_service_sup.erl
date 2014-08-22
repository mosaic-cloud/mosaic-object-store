%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-module (ms_os_service_sup).


-export ([start_link/0, start_link/1]).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


start_link () ->
	start_link (ms_os_service_sup).

start_link (Type)
		when is_atom (Type) ->
	{supervisor, QualifiedName, Configuration} = configuration (Type),
	ve_supervisor_tools:start_link (QualifiedName, Configuration).


%----------------------------------------------------------------------------


configuration (ms_os_service_sup) ->
	{supervisor,
			{local, ms_os_service_sup},
			{one_for_one, [
					{process, {local, ms_os_cowboy}, ms_os_cowboy, defaults},
					{process, {local, ms_os_backend}, ms_os_backend, defaults}
			]}}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------
