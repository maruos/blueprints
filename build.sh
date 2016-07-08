#!/bin/bash -e

#
# Build container images for Maru.
#
# Most of the actual image building logic is left to blueprint "plugins".
#

print_help () {
    cat <<EOF
Build container images for Maru

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

OPT_BLUEPRINT="debian"
OPT_NAME="$OPT_BLUEPRINT"
while true; do
    case $1 in
        -b|--blueprint)
            if [ -n "$2" ] ; then
                OPT_BLUEPRINT="$2"
                shift
            else
                echo >&2 "Error: --blueprint requires a non-empty option argument"
                exit 2
            fi
            ;;
        -n|--name)
            if [ -n "$2" ] ; then
                OPT_NAME="$2"
                shift
            else
                echo >&2 "Error: --name requires a non-empty option argument"
                exit 2
            fi
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        -?*)
            echo >&2 "Error: Unknown option ${1}"
            print_help
            exit 2
            ;;
        *)
            break
            ;;
    esac
    shift
done

OUT_DIR="$(pwd)/out"
ROOTFS_DIR="${OUT_DIR}/${OPT_NAME}/rootfs"
ROOTFS_TAR="${OUT_DIR}/${OPT_NAME}.tar.gz"

# can't mount this during docker build since it requires privilege...
if [ ! -d /proc/sys/fs/binfmt_misc ] ; then
    mecho "enabling binfmts for cross-bootstrapping..."
    mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
fi
update-binfmts --enable

plugin="$(pwd)/blueprint/${OPT_BLUEPRINT}/plugin.sh"
if [ ! -e "$plugin" ] ; then
    echo >&2 "${OPT_BLUEPRINT} isn't a valid blueprint!"
    exit 2
fi

mecho "loading distro plugin..."
pushd >/dev/null "$(dirname "$plugin")"
source $plugin

mecho "building image..."
blueprint_build "$OPT_NAME" "$ROOTFS_DIR"

popd >/dev/null

mecho "creating a rootfs compressed archive..."
tar czf "$ROOTFS_TAR" -C "$(dirname "$ROOTFS_DIR")" "$(basename "$ROOTFS_DIR")"

mecho "cleaning up..."
blueprint_cleanup "$OPT_NAME" "$ROOTFS_DIR"

mecho "Build success! See $ROOTFS_TAR"
