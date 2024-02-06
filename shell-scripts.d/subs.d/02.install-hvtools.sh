#!/bin/ash
# shellcheck shell=ash

export WORKDIR=$(realpath $(dirname $0))
source ${WORKDIR}/../.env

if [ -z "${INSTALL_HVTOOLS}" ] ||
   [[ -n "${INSTALL_HVTOOLS}" && ${INSTALL_HVTOOLS} -ne 1 ]]; then

    exit 0
fi

# https://wiki.alpinelinux.org/wiki/Hyper-V_guest_services

echo "Install hvtools & start services..."
apk add -q --no-cache -u \
    hvtools hvtools-openrc openrc

# Start services
rc-service hv_fcopy_daemon start
rc-service hv_kvp_daemon start
rc-service hv_vss_daemon start

# Ensure these services start on boot
rc-update add hv_fcopy_daemon
rc-update add hv_kvp_daemon
rc-update add hv_vss_daemon

exit 0
