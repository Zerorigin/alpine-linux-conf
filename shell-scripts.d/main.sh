#!/bin/ash
# shellcheck shell=ash

export WORKDIR=$(realpath $(dirname $0))
export SUB_DIR=${WORKDIR}/subs.d

source ${WORKDIR}/.env

function main() {
    export SCRIPTS=$(find ${SUB_DIR} -maxdepth 1 -iname '*.sh' -type f -exec basename {} \; | sort -u)
    for it in $SCRIPTS; do
        ash "${SUB_DIR}/${it}"
    done
}

main

exit 0
