#!/bin/sh -e

#
# install packages
#

apt-get update

# first install "Recommends" since we overwrite some /etc config files
apt-get -y install xfce4-terminal \
    vim-tiny \
    iceweasel \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    ristretto

# install maru package (this will always return failed exit status)
dpkg -i maru_* || true

# install all missing packages in "Depends"
apt-get -y install -f

# get rid of xscreensaver and annoying warning
apt-get -y purge xscreensaver xscreensaver-data

#
# shrink the rootfs as much as possible
#

# clean cached packages
apt-get -y autoremove
apt-get autoclean
apt-get clean

# clean package lists (this can be recreated with apt-get update)
rm -rf /var/lib/apt/lists/*
