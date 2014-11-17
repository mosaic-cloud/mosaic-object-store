#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

_identifier="${mosaic_service_identifier:-000000008e473639744522bc8ebf89628b746387}"

## chunk::be1d894b132982aa08a6adf7e406c9a9::begin ##
if test -n "${mosaic_service_temporary:-}" ; then
	_tmp="${mosaic_service_temporary:-}"
elif test -n "${mosaic_temporary:-}" ; then
	_tmp="${mosaic_temporary}/services/${_identifier}"
else
	_tmp="${TMPDIR:-/tmp}/mosaic/services/${_identifier}"
fi
## chunk::be1d894b132982aa08a6adf7e406c9a9::end ##

_fqdn="${mosaic_node_fqdn:-mosaic-0.loopback.vnet}"

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
		mosaic_service_identifier="${_identifier}"
		mosaic_node_fqdn="${_fqdn}"
)

if test -n "${MOSAIC_OBJECT_STORE_ENDPOINT_IP:-}" ; then
	_erl_args+=(
			-ms_os_service service_ip "<<\"${MOSAIC_OBJECT_STORE_ENDPOINT_IP}\">>"
	)
fi
if test -n "${MOSAIC_OBJECT_STORE_ENDPOINT_PORT:-}" ; then
	_erl_args+=(
			-ms_os_service service_port "${MOSAIC_OBJECT_STORE_ENDPOINT_PORT}"
	)
fi

## chunk::da43d7ef47da796de30612bd22b4e475::begin ##
mkdir -p -- "${_tmp}"
cd -- "${_tmp}"

exec {_lock}<"${_tmp}"
if ! flock -x -n "${_lock}" ; then
	echo '[ee] failed to acquire lock; aborting!' >&2
	exit 1
fi
## chunk::da43d7ef47da796de30612bd22b4e475::end ##

exec env "${_erl_env[@]}" "${_erl_bin}" "${_erl_args[@]}"

exit 1
