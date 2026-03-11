#!/usr/bin/env bash

sudo apt update
sudo apt upgrade
sudo apt install git base-devel diffutils unzip patch bc make automake libtool

git clone https://aur.archlinux.org/yay.git
cd yay

makepkg -si

export PATH="$PATH:/path/to/yay"

source ~/.bashrc
# 或
source ~/.bash_profile

yay
