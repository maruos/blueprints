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
# Build container images for Maru OS.
#
# Most of the actual image building logic is left to blueprint plugins.
#

set -e
set -u

readonly MARU_TAG="maru-$(git describe)"

print_help () {
    cat <<EOF
Build container images for Maru OS

Usage: build.sh [OPTIONS]

    -b, --blueprint     Blueprint to use, currently only 'debian'.
                        Defaults to debian.

    -n, --name          Optional container name. Defaults to blueprint name.
                        This is used to set /etc/hostname in the rootfs.
EOF
}

mecho () {
    echo "--> ${1}"
}

mount_binfmts () {
    if ! mount | grep -q 'binfmt_misc' ; then
        mecho "enabling binfmts for cross-bootstrapping..."
        mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
    fi
    update-binfmts --enable
}

cleanup () {
    local opt_name="$1"
    local rootfs_dir="$2"
    local tmp_dir="$3"

    mecho "cleaning up..."
    blueprint_cleanup "$opt_name" "$rootfs_dir"
    if [ -d "$tmp_dir" ] ; then
        rm -rf "$tmp_dir"
    fi
}

OPT_BLUEPRINT="debian"
OPT_NAME="$OPT_BLUEPRINT"

ARGS="$(getopt -o b:n:h --long blueprint:,name:,help -n 'build.sh' -- "$@")"
if [ $? != 0 ] ; then
    echo >&2 "Error parsing options!"
    exit 2
fi

eval set -- "$ARGS"

while true; do
    case "$1" in
        -b|--blueprint) OPT_BLUEPRINT="$2"; shift 2 ;;
        -n|--name) OPT_NAME="$2"; shift 2 ;;
        -h|--help) print_help; exit 0 ;;
        --) shift; break ;;
    esac
done

readonly OUT_DIR="$(pwd)/out"
readonly TMP_DIR="${OUT_DIR}/${OPT_NAME}-intermediates"
readonly ROOTFS_DIR="${TMP_DIR}/rootfs"
readonly ROOTFS_TAR="${OUT_DIR}/${MARU_TAG}-${OPT_NAME}-rootfs.tar.gz"

plugin="$(pwd)/blueprint/${OPT_BLUEPRINT}/plugin.sh"
if [ ! -e "$plugin" ] ; then
    echo >&2 "${OPT_BLUEPRINT} isn't a valid blueprint!"
    exit 2
fi

# prep for cross-bootstrapping
mount_binfmts

mecho "loading distro plugin..."
pushd >/dev/null "$(dirname "$plugin")"

source "$plugin"

trap "cleanup $OPT_NAME $ROOTFS_DIR $TMP_DIR" EXIT

mecho "building image..."
blueprint_build "$OPT_NAME" "$ROOTFS_DIR" "$@"

mecho "creating a rootfs compressed archive..."
tar czf "$ROOTFS_TAR" -C "$(dirname "$ROOTFS_DIR")" "$(basename "$ROOTFS_DIR")"

# prepend hash to release for sanity checks
sha1="$(sha1sum "$ROOTFS_TAR" | cut -c -8)"
release="${ROOTFS_TAR%.tar.gz}-${sha1}.tar.gz"
mv "$ROOTFS_TAR" "$release"

mecho "Build success! See $release"
