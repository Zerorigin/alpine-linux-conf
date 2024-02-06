#!/bin/ash
# shellcheck shell=ash

export WORKDIR=$(realpath $(dirname $0))
source ${WORKDIR}/../.env

export USR=${USERNAME}
export LOCK=/etc/doas.d/doas.conf

apk add -q --no-cache -u doas openssl

export IS_EXISTS=$(grep -Eo "^${USR}:" /etc/passwd | wc -l)

if [ -z "${ADD_NEW_USER}" ] ||
   [[ -n "${ADD_NEW_USER}" && ${ADD_NEW_USER} -ne 1 ]] ||
   [ ${IS_EXISTS} -eq 1 ]; then

    echo "adduser: user '${USR}' in use."
    exit 0

fi

if [ $(getent passwd ${USER_UID} | wc -l) -ge 1 ]; then
    echo "Create user '${USR}'..."
    adduser -D ${USR} ${USR}
else
    echo "Create user '${USR}' with UID (${USER_UID})..."
    adduser -D -u ${USER_UID} ${USR} ${USR}
fi

echo "${USR}:$(openssl passwd -6 ${PASSWORD})" | chpasswd

addgroup ${USR} wheel

if [ ! -f ${LOCK} ] ||
   [ $(grep -Eo 'permit\s+persist\s+:wheel' /etc/doas.conf | wc -l) -eq 0 ] ||
   [ $(grep -Eo 'permit\s+persist\s+:wheel' /etc/doas.d/doas.conf | wc -l) -eq 0 ]; then

    if [ ! -d /etc/doas.d ]; then
        mkdir -p /etc/doas.d
    fi

    touch ${LOCK}
    chattr -i ${LOCK}
    echo "permit persist :wheel" >> ${LOCK}
    chattr +i ${LOCK}
    chattr -R +u /etc/doas.d

fi

exit 0
