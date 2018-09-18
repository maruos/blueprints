#!/bin/bash

#
# Copyright 2015-2016 Preetam J. D'Souza
# Copyright 2016 The Maru OS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e
set -u

install () {
    local pkgs="$1"

    # first install "Recommends" since we overwrite some /etc config files
    apt-get -y install $pkgs

    # install maru package (this will always return failed exit status)
    dpkg -i maru_* || true

    # install all missing packages in "Depends"
    apt-get -y install -f
}

install_minimal () {
    local pkgs="$1"

    # first install "Recommends" since we overwrite some /etc config files
    apt-get -y install --no-install-recommends $pkgs

    # install maru package (this will always return failed exit status)
    dpkg -i maru_* || true

    # install all missing packages in "Depends"
    apt-get -y install --no-install-recommends -f

    # HACK for now to skip libreoffice launcher icons
    mv /home/maru/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel-minimal.xml \
        /home/maru/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
    chown -R maru:maru /home/maru/.config
}

OPT_MINIMAL=false
OPT_RELEASE=""
while [ $# -gt 0 ]; do
    case $1 in
        -r|--release) OPT_RELEASE="$2"; shift 2 ;;
        -m|--minimal) OPT_MINIMAL=true; shift ;;
        *) echo >&2 "[x] Unrecognized option: '$1'"; exit 2 ;;
    esac
done

recommends_min="xfce4-terminal
vim-tiny
firefox-esr
ristretto"

# WORKAROUND for https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=908396
if [ "$OPT_RELEASE" = "stretch" ] ; then
    echo "[!] Installing older firefox-esr to work around Debian bug #908396"
    recommends_min="${recommends_min/firefox-esr/firefox-esr=52.9.0esr-1~deb9u1}"
fi

recommends="$recommends_min
libreoffice-writer
libreoffice-calc
libreoffice-impress"


#
# do stuff that requires a chroot context
#

# disable sshd services by default
# systemd syncs with sysvinit so use update-rc.d too
/usr/sbin/update-rc.d ssh disable
if [ -e /etc/systemd/system/sshd.service ] ; then
    rm /etc/systemd/system/sshd.service
fi

#
# install packages
#

apt-get clean && apt-get update

# add maru apt repository for installing dependencies
apt-get install -y curl gnupg
curl -fsSL https://maruos.com/static/gpg.txt | apt-key add -
cat > /etc/apt/sources.list.d/maruos.list <<EOF
deb http://packages.maruos.com/debian testing/
EOF
apt-get update

if [ "$OPT_MINIMAL" = true ] ; then
    install_minimal "$recommends_min"
else
    install "$recommends"
fi

# delete maru apt repository for now (upgrades not tested)
rm /etc/apt/sources.list.d/maruos.list

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

#
# final prep
#

# root acount is unnecessary since default account + sudo is all set up
passwd -dl root
