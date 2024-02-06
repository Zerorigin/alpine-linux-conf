#!/bin/ash
# shellcheck shell=ash

echo "Install toolbelts..."
apk add -q --no-cache -u \
    ca-certificates ca-certificates-bundle openssl tzdata \
    curl wget \
    git mercurial \
    jq yq \
    helix nano vim

exit 0
