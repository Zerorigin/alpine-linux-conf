#!/bin/ash
# shellcheck shell=ash

export WORKDIR=$(realpath $(dirname $0))
source ${WORKDIR}/../.env

if [ -z "${MOUNT_SAMBA}" ] ||
   [[ -n "${MOUNT_SAMBA}" && ${MOUNT_SAMBA} -ne 1 ]]; then

    exit 0
fi

apk add -q --no-cache -u \
    cifs-utils openrc

rc-update add netmount

echo "Config samba mount point..."

# Config auth info...
export TMP=$(mktemp)
cat > ${TMP} << EOF
username=${SMB_USR}
password=${SMB_PIN}
domain=${SMB_DOM}
EOF

export SUF=$(md5sum ${TMP} | cut -c1-10)
export FN="/root/.smb.cred_${SUF}"
mv -f ${TMP} ${FN}
chmod 600 ${FN}

export USR_UID=$(getent passwd ${USERNAME} | cut -d: -f3)
export USR_GID=$(getent group ${USERNAME} | cut -d: -f3)
export SMB_OPTS="_netdev,credentials=${FN},vers=3,sec=ntlmv2i,iocharset=utf8,mapchars,resilienthandles,rwpidforward,intr,sfu,idsfromsid,modefromsid,setuids,gid=${USR_GID},uid=${USR_UID},serverino,nobrl,cache=strict,fsc,acl,cifsacl,user_xattr,exec,rw,nofail"


echo "Add mount point to /etc/fstab..."
if [ $(grep -E "^//${SMB_SVR}/${SMB_SHR}.*/root/\.smb\.cred_.*" /etc/fstab | wc -l) -ge 1 ]; then
    sed -e "s|^//${SMB_SVR}/${SMB_SHR}.*/root/\.smb\.cred_.*|//${SMB_SVR}/${SMB_SHR} ${SMB_MNTP} smb3 ${SMB_OPTS} 0 0|g" -i /etc/fstab
else
    cat >> /etc/fstab << EOF
//${SMB_SVR}/${SMB_SHR} ${SMB_MNTP} smb3 ${SMB_OPTS} 0 0
EOF
fi

mkdir -p ${SMB_MNTP}
chown ${USERNAME}:${USERNAME} ${SMB_MNTP}

rc-service netmount restart

exit 0
