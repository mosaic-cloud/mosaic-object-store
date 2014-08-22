#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

_fqdn="${mosaic_node_fqdn:-mosaic-0.loopback.vnet}"

if test -n "${mosaic_service_temporary:-}" ; then
	_tmp="${mosaic_service_temporary:-}"
elif test -n "${mosaic_temporary:-}" ; then
	_tmp="${mosaic_temporary}/services/mosaic-object-store"
else
	_tmp="${TMPDIR:-/tmp}/mosaic/services/mosaic-object-store"
fi

_erl_args+=(
		-noinput -noshell
		-name "mosaic-object-store@${_fqdn}"
		-setcookie "${_erl_cookie}"
		-boot start_sasl
		-config "${_erl_libs}/ms_os_service/priv/ms_os_service.config"
		-run ms_os_service_app boot
)
_erl_env+=(
		mosaic_service_temporary="${_tmp}"
		mosaic_node_fqdn="${_fqdn}"
)

mkdir -p -- "${_tmp}"
cd -- "${_tmp}"

exec env "${_erl_env[@]}" "${_erl_bin}" "${_erl_args[@]}"

exit 1
