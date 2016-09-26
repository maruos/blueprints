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

# first install "Recommends" since we overwrite some /etc config files
apt-get -y install xfce4-terminal \
    vim-tiny \
    firefox-esr \
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
