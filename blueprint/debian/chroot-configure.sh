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

#
# Container configuration that requires a chroot context goes here.
#

set -e
set -u

install () {
    local pkgs="$1"

    # first install "Recommends" since we overwrite some /etc config files
    apt-get -q -y install $pkgs

    # install maru package (this will always return failed exit status)
    dpkg -i maru_* || true

    # install all missing packages in "Depends"
    apt-get -q -y install -f
}

install_minimal () {
    local pkgs="$1"

    # first install "Recommends" since we overwrite some /etc config files
    apt-get -q -y install --no-install-recommends $pkgs

    # install maru package (this will always return failed exit status)
    dpkg -i maru_* || true

    # install all missing packages in "Depends"
    apt-get -q -y install --no-install-recommends -f

    # HACK for now to skip libreoffice launcher icons
    mv /home/maru/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel-minimal.xml \
        /home/maru/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
    chown -R maru:maru /home/maru/.config
}

add_maru_key () {
    apt-get clean
    apt-get -q update
    apt-get -q -y install curl gnupg
    curl -fsSL https://maruos.com/static/gpg.txt | apt-key add -
}

shrink_rootfs () {
    # clean cached packages
    apt-get -q -y autoremove
    apt-get autoclean
    apt-get clean

    # clean package lists (this can be recreated with apt-get update)
    rm -rf /var/lib/apt/lists/*
}

# WORKAROUND for https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=909498
workaround_909498 () {
    [ "$OPT_RELEASE" = "stretch" ] && [ "$(dpkg --print-architecture)" = "armhf" ]
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

echo "[*] Running $(basename "$0")..."

recommends_min="xfce4-terminal
vim-tiny
firefox-esr
ristretto"

if workaround_909498 ; then
    echo "[!] Installing firefox-esr from oldstable to work around Debian bug #909498"
    cat > /etc/apt/sources.list.d/jessie.list <<EOF
deb http://security.debian.org/debian-security jessie/updates main
EOF
    recommends_min="${recommends_min/firefox-esr/firefox-esr/oldstable}"
fi

recommends="$recommends_min
libreoffice-writer
libreoffice-calc
libreoffice-impress"

echo "[*] Installing packages..."

# add maru apt repository for installing dependencies
add_maru_key
cat > /etc/apt/sources.list.d/maruos.list <<EOF
deb http://packages.maruos.com/debian testing/
EOF

apt-get -q update

if [ "$OPT_MINIMAL" = true ] ; then
    install_minimal "$recommends_min"
else
    install "$recommends"
fi

if workaround_909498 ; then
    # prevent `apt-get upgrade` from auto-upgrading firefox-esr
    apt-mark hold firefox-esr
fi

# delete maru apt repository for now (upgrades not tested)
rm /etc/apt/sources.list.d/maruos.list

# get rid of xscreensaver and annoying warning
apt-get -y purge xscreensaver xscreensaver-data

echo "[*] Configuring system..."

echo "  [*] Disabling sshd..."
# disable sshd services by default
# systemd syncs with sysvinit so use update-rc.d too
/usr/sbin/update-rc.d ssh disable
if [ -e /etc/systemd/system/sshd.service ] ; then
    rm /etc/systemd/system/sshd.service
fi

echo "  [*] Masking remount of /sys/kernel/debug..."
# mask the remount of /sys/kernel/debug
# because it breaks webview_zygote on some devices
ln -s /dev/null /etc/systemd/system/sys-kernel-debug.mount

# root acount is unnecessary since default account + sudo is all set up
passwd -dl root >/dev/null

echo "[*] Optimizing rootfs..."

shrink_rootfs

echo "[*] All $(basename "$0") tasks completed successfully."
