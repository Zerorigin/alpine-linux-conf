#!/bin/ash
# shellcheck shell=ash

export WORKDIR=$(realpath $(dirname $0))
source ${WORKDIR}/../.env

echo "Modify RootFs..."

if [ -z "${MODIFY_ROOTFS}" ] ||
   [[ -n "${MODIFY_ROOTFS}" && ${MODIFY_ROOTFS} -ne 1 ]]; then
    echo "Non-implementation of modifications, early exit..."
fi


chown -R root:root $(realpath $(find ${WORKDIR}/../../rootfs/))
chmod 0644 $(realpath $(find ${WORKDIR}/../../rootfs/ -type f))
chmod a+x $(realpath $(find ${WORKDIR}/../../rootfs/ -type f -iname '*.sh'))
cp -af ${WORKDIR}/../../rootfs/* /

echo "Retrofitting completed."

exit 0
