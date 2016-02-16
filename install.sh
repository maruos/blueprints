#!/bin/sh -e

# make sure we've got a working nameserver
# (on a fresh rootfs this may not be set correctly)
echo "nameserver 8.8.8.8" > /etc/resolv.conf

apt-get update

# first install "Recommends" since we
# overwrite some /etc config files
apt-get install xfce4-terminal \
    vim-tiny \
    iceweasel \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    ristretto

# install maru package (this will always return failed exit status)
dpkg -i maru_* || true

# install all missing packages in "Depends"
apt-get install -f

## shrink the rootfs as much as possible ##

# clean cached packages
apt-get autoremove
apt-get autoclean
apt-get clean

# clean package lists (this can be recreated with apt-get update)
rm -rf /var/lib/apt/lists/*
