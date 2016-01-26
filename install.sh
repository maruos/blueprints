#!/bin/sh -e

# make sure we've got a working nameserver
# (on a fresh rootfs this may not be set correctly)
echo "nameserver 8.8.8.8" > /etc/resolv.conf

apt-get update

# first install "Recommends" since we
# overwrite some /etc config files
apt-get install xfce4-terminal xfce4-screenshooter \
    lxtask \
    iputils-ping \
    gcc python \
    vim git \
    iceweasel \
    libreoffice \
    ristretto

# install maru package (this will always return failed exit status)
dpkg -i maru_* || true

# install all missing packages in "Depends"
apt-get install -f
