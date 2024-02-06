#!/bin/ash
# shellcheck shell=ash

if [ -z "${LD_PRELOAD}" ]; then
    export LD_PRELOAD=$(find /usr/lib/ -type f -regex '.*\/libmimalloc.*' | tail -n 1)
fi
