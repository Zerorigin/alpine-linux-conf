#!/bin/ash
# shellcheck shell=ash

echo "Install toolbelts..."
apk add -q --no-cache -u \
    busybox-extras mimalloc2 tzdata \
    bridge-utils iproute2 net-tools \
    ca-certificates ca-certificates-bundle openssl \
    curl wget \
    git mercurial \
    jq yq \
    helix nano vim \
    tmux

exit 0
