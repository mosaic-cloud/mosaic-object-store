
{application, ms_os_component, [
	{description, "mOSAIC object store component"},
	{vsn, "1"},
	{applications, [kernel, stdlib, mosaic_component]},
	{modules, []},
	{registered, []},
	{mod, {mosaic_dummy_app, defaults}},
	{env, []}
]}.
