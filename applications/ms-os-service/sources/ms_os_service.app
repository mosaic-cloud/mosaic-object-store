
{application, ms_os_service, [
	{description, "mOSAIC Services -- Object Store -- Service"},
	{vsn, "1"},
	{applications, [kernel, stdlib, ve_cowboy, ve_tools]},
	{modules, []},
	{registered, []},
	{mod, {ms_os_service_app, defaults}},
	{env, []}
]}.
