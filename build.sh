#!/bin/bash -e

#
# Build container images for Maru
#

print_help () {
    cat <<EOF
Build container images for Maru

Usage: build.sh [OPTIONS]

    -t, --template  Distro template to use, currently only 'debian'.
                    Defaults to debian.
                    This will search maru custom templates first before
                    resorting to LXC default templates.

    -n, --name      Container name.
                    This is used to set /etc/hostname in the rootfs.
EOF
}

mecho () {
    echo "--> ${1}"
}


bootstrap_lxc () {
    # must be an absolute path for custom template location
    local template="$1"
    local name="$2"
    local dir="$3"
    local arch="${4:-armhf}"

    lxc-create -t "$template" -n "$name" --dir "$dir" -- -a "$arch"
}

set -x

OPT_TEMPLATE="debian"
OPT_NAME="$OPT_TEMPLATE"
while true; do
    case $1 in
        -t|--template)
            if [ -n "$2" ] ; then
                OPT_TEMPLATE="$2"
                shift
            else
                echo >&2 "Error: --template requires a non-empty option argument"
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

ROOTFS_DIR="${MARU_OUT}/${OPT_NAME}/rootfs"
ROOTFS_TAR="${MARU_OUT}/${OPT_NAME}.tar.gz"

export DEBIAN_FRONTEND=noninteractive 
export DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C 
export LANGUAGE=C 
export LANG=C 

# can't mount this during docker build since it requires privilege...
if [ ! -d /proc/sys/fs/binfmt_misc ] ; then
    mecho "enabling binfmts for cross-bootstrapping..."
    mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
    update-binfmts --enable
fi

mecho "bootstrapping a minimal rootfs..."
# prefer to use our custom templates
template="${MARU_TEMPLATES}/${OPT_TEMPLATE}.sh"
if [ ! -e "$template" ] ; then
    # ...but fall back to default templates
    template="$OPT_TEMPLATE"
fi
bootstrap_lxc "$template" "$OPT_NAME" "$ROOTFS_DIR"

mecho "installing maru configuration in rootfs..."
if [ -d "$OPT_TEMPLATE" ] ; then
    pushd >/dev/null "$OPT_TEMPLATE"
    mecho "building maru debpkg..."
    make
    cp maru*.deb "${ROOTFS_DIR}/tmp"
    cp configure.sh "${ROOTFS_DIR}/tmp"
    chroot "$ROOTFS_DIR" bash -c "cd /tmp && ./configure.sh"
    popd >/dev/null
else
    echo >&2 "Warning: cannot find config dir for ${OPT_TEMPLATE}, skipping configuration..."
fi

mecho "creating a rootfs compressed archive..."
tar czf "$ROOTFS_TAR" -C "$(dirname "$ROOTFS_DIR")" "$(basename "$ROOTFS_DIR")"

mecho "Build success! See $ROOTFS_TAR"
