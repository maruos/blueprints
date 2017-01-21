#!/bin/sh

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

readonly RECOMMENDS="xfce4-terminal
vim-tiny
firefox-esr
libreoffice-writer
libreoffice-calc
libreoffice-impress
ristretto"

install () {
    # first install "Recommends" since we overwrite some /etc config files
    apt-get -y install $RECOMMENDS

    # install maru package (this will always return failed exit status)
    dpkg -i maru_* || true

    # install all missing packages in "Depends"
    apt-get -y --allow-unauthenticated install -f
}

install_minimal () {
    # first install "Recommends" since we overwrite some /etc config files
    apt-get -y install --no-install-recommends $RECOMMENDS

    # install maru package (this will always return failed exit status)
    dpkg -i maru_* || true

    # install all missing packages in "Depends"
    apt-get -y --allow-unauthenticated install --no-install-recommends -f
}

OPT_MINIMAL=false
while true; do
    case "$1" in
        -m|--minimal) OPT_MINIMAL=true; shift ;;
        --) shift; break ;;
        *-) echo >&2 "Unrecognized option $1"; exit 2 ;;
        *) break;
    esac
done


#
# do stuff that requires a chroot context
#

# some versions of LXC set a random root password,
# so ensure the password is set to 'root'
echo "root:root" | chpasswd

#
# install packages
#

apt-get clean && apt-get update

if [ "$OPT_MINIMAL" = true ] ; then
    install_minimal
else
    install
fi

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
