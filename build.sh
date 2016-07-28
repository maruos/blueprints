#!/bin/bash

#
# Build container images for Maru OS.
#
# Most of the actual image building logic is left to blueprint plugins.
#

set -e

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

OUT_DIR="$(pwd)/out"
TMP_DIR="${OUT_DIR}/${OPT_NAME}-intermediates"
ROOTFS_DIR="${TMP_DIR}/rootfs"
ROOTFS_TAR="${OUT_DIR}/${OPT_NAME}.tar.gz"

plugin="$(pwd)/blueprint/${OPT_BLUEPRINT}/plugin.sh"
if [ ! -e "$plugin" ] ; then
    echo >&2 "${OPT_BLUEPRINT} isn't a valid blueprint!"
    exit 2
fi

# prep for cross-bootstrapping
mount_binfmts

mecho "loading distro plugin..."
pushd >/dev/null "$(dirname "$plugin")"

source $plugin

mecho "building image..."
blueprint_build "$OPT_NAME" "$ROOTFS_DIR" "$@"

mecho "creating a rootfs compressed archive..."
tar czf "$ROOTFS_TAR" -C "$(dirname "$ROOTFS_DIR")" "$(basename "$ROOTFS_DIR")"

mecho "cleaning up..."
blueprint_cleanup "$OPT_NAME" "$ROOTFS_DIR"
if [ -d "$TMP_DIR" ] ; then
    rm -rf "$TMP_DIR"
fi

popd >/dev/null

mecho "Build success! See $ROOTFS_TAR"
