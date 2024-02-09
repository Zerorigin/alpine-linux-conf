#!/bin/ash
# shellcheck shell=ash

export WORKDIR=$(realpath $(dirname $0))
source ${WORKDIR}/../.env

if [ -z "${INSTALL_DOCKER}" ] ||
   [[ -n "${INSTALL_DOCKER}" && ${INSTALL_DOCKER} -ne 1 ]]; then

    exit 0
fi

# https://wiki.alpinelinux.org/wiki/Docker

#export USR=$(
#    grep ':1000:' /etc/passwd |
#    grep -Eo '[[:alnum:]|_-]+' |
#    head -n 1
#)
export USR=${USERNAME}


echo "Install docker toolbelts..."
apk add -q --no-cache -u \
    docker \
    docker-cli-compose \
    jq openrc openssl

# Modify user
addgroup ${USR} docker

# Config cgroups
sed \
    -e 's/^#\?\s*\?rc_cgroup_mode=.*/rc_cgroup_mode="unified"/g' \
    -i /etc/rc.conf


# Config docker daemon conf.
export JSON_FILE=/etc/docker/daemon.json
if [ ! -f "${JSON_FILE}" ]; then
    mkdir -p ${JSON_FILE%\/*}
    echo "{}" > ${JSON_FILE}
fi

dos2unix ${JSON_FILE}
export JSON_TEXT='''
{
    "experimental": true,
    "hosts": [
        "tcp://127.0.0.1:2376",
        "unix:///var/run/docker.sock"
    ],
    "icc": true,
    "ip-forward": true,
    "iptables": true,
    "ipv6": false,
    "live-restore": false,
    "log-level": "warn",
    "log-opts": {
        "max-file": "4",
        "max-size": "1m"
    },
    "no-new-privileges": false
}
'''
export JSON_TEXT=$(echo ${JSON_TEXT} | dos2unix)
export JSON_TEMP=$(jq ". += ${JSON_TEXT}" ${JSON_FILE})
echo ${JSON_TEMP} | jq -S . > ${JSON_FILE}


# Ensure start the Docker daemon at boot.
rc-update add cgroups
rc-update add docker default


# Start docker daemon.
service cgroups restart
service docker start


# Config docker rootless
if [ -z "${DOCKER_ROOTLESS}" ] ||
   [[ -n "${DOCKER_ROOTLESS}" && ${DOCKER_ROOTLESS} -ne 1 ]]; then
    export JSON_LESS=$(jq 'del(."userns-remap")' ${JSON_FILE})
    echo ${JSON_LESS} | jq -S . > ${JSON_FILE}
    apk del -q docker-rootless-extras
    service docker restart
    exit 0
fi

echo "Config Docker run with rootless mode..."
apk add -q --no-cache -u docker-rootless-extras


# Modify docker rootless user
if [ $(getent passwd dockremap | wc -l) -eq 0 ]; then
    adduser -SDHs /sbin/nologin dockremap
    addgroup -S dockremap
fi

if [ $(grep 'dockremap' /etc/subuid | wc -l) -eq 0 ]; then
    echo dockremap:$(grep dockremap /etc/passwd|cut -d: -f3):65536 >> /etc/subuid
fi

if [ $(grep 'dockremap' /etc/subgid | wc -l) -eq 0 ]; then 
    echo dockremap:$(grep dockremap /etc/paswwd|cut -d: -f4):65536 >> /etc/subgid
fi



# Config docker daemon rootless  conf.
export JSON_FILE=/etc/docker/daemon.json
if [ ! -f "${JSON_FILE}" ]; then
    mkdir -p ${JSON_FILE%\/*}
    echo "{}" > ${JSON_FILE}
fi

dos2unix ${JSON_FILE}
export JSON_TEXT='''
{
    "userns-remap": "dockremap",
    "experimental": true,
    "hosts": [
        "tcp://127.0.0.1:2376",
        "unix:///var/run/docker.sock"
    ],
    "ip-forward": true,
    "iptables": true,
    "icc": true,
    "ipv6": false,
    "live-restore": false,
    "log-level": "warn",
    "log-opts": {
        "max-file": "4",
        "max-size": "1m"
    },
    "no-new-privileges": false
}
'''
export JSON_TEXT=$(echo ${JSON_TEXT} | dos2unix)
export JSON_TEMP=$(jq ". += ${JSON_TEXT}" ${JSON_FILE})
echo ${JSON_TEMP} | jq -S . > ${JSON_FILE}

# Restart docker daemon
service docker restart

exit 0
