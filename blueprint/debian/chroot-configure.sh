#!/bin/sh -e

## post-bootstrap configuration ##

# make sure we've got a working nameserver
# (on a fresh rootfs this may not be set correctly)
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# make sure hostname is in /etc/hosts to avoid hostname resolution errors
cat >/etc/hosts <<EOF
127.0.0.1   localhost
127.0.1.1   $(cat /etc/hostname)
::1     localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# disable any default.target (LXC symlinks to multi-user.target by default)
SYSTEMD_DEFAULT_TARGET=/etc/systemd/system/default.target
if [ -e "$SYSTEMD_DEFAULT_TARGET" ] ; then
    rm "$SYSTEMD_DEFAULT_TARGET"
fi

## install packages ##

apt-get update

# first install "Recommends" since we
# overwrite some /etc config files
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

## shrink the rootfs as much as possible ##

# clean cached packages
apt-get -y autoremove
apt-get autoclean
apt-get clean

# clean package lists (this can be recreated with apt-get update)
rm -rf /var/lib/apt/lists/*
