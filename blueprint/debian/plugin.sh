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

readonly BLUEPRINT_NAME="DEBIAN"

readonly DEFAULT_RELEASE="buster"
readonly DEFAULT_ARCH="armhf"

# script to run inside the chroot
readonly CHROOT_SCRIPT="chroot-configure.sh"

pecho () {
    echo "[ $BLUEPRINT_NAME ] $1"
}

print_help () {
    cat <<EOF
Blueprint for building Debian images.

Debian-specific options:

    -r, --release   Debian release to use as the image base.
                    Defaults to '$DEFAULT_RELEASE'.

    -a, --arch      Architecture of generated image.
                    Defaults to '$DEFAULT_ARCH'.

    -m, --minimal   Minimize the image size as much as possible by dropping
                    non-essential packages.
EOF
}

bootstrap () {
    local name="$1"
    local rootfs="$2"
    local release="$3"
    local arch="$4"

    pecho "bootstrapping rootfs..."
    mkdir -p "$rootfs"
    DOWNLOAD_KEYSERVER="keyserver.ubuntu.com" \
    lxc-create -t download -n "$name" --dir "$rootfs" -- \
        --dist debian --arch "$arch" --release "$release"
}

chroot_mount () {
    local rootfs="$1"
    mount -t proc proc "${rootfs}/proc"
    mount --bind /dev "${rootfs}/dev"
}

chroot_umount () {
    local rootfs="$1"
    umount -q "${rootfs}/proc"
    umount -q "${rootfs}/dev"
}

configure () {
    local name="$1"
    local rootfs="$2"
    local release="$3"
    local minimal="$4"

    # make sure we've got a working nameserver
    # (on a fresh rootfs this may not be set correctly)
    echo "nameserver 8.8.8.8" > "${rootfs}/etc/resolv.conf"

    # make sure hostname is in /etc/hosts to avoid hostname resolution errors
    cat > "${rootfs}/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   $(cat "${rootfs}/etc/hostname")
::1     localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

    # disable any default.target
    # (LXC template symlinks to multi-user.target by default)
    local SYSTEMD_DEFAULT_TARGET="${rootfs}/etc/systemd/system/default.target"
    rm -f "$SYSTEMD_DEFAULT_TARGET"
    ln -s "/lib/systemd/system/graphical.target" "$SYSTEMD_DEFAULT_TARGET"

    export DEBIAN_FRONTEND=noninteractive
    export DEBCONF_NONINTERACTIVE_SEEN=true
    export LC_ALL=C
    export LANGUAGE=C
    export LANG=C

    pecho "building maru debpkg..."
    make
    cp maru*.deb "${rootfs}/tmp"

    pecho "configuring rootfs..."
    cp "$CHROOT_SCRIPT" "${rootfs}/tmp"

    local script_args="-r ${release}"
    if [ "$minimal" = true ] ; then
        script_args="${script_args} --minimal"
    fi

    chroot_mount "$rootfs"
    chroot "$rootfs" bash -c "cd /tmp && ./${CHROOT_SCRIPT} $script_args"
    chroot_umount "$rootfs"
}

blueprint_build () {
    local name="$1"; shift
    local rootfs="$1"; shift

    #
    # parse blueprint-specific options
    #

    local release="$DEFAULT_RELEASE"
    local arch="$DEFAULT_ARCH"
    local minimal=false

    local ARGS="$(getopt -o r:a:mh --long release:,arch:,minimal,help -n "$BLUEPRINT_NAME" -- "$@")"
    if [ $? != 0 ] ; then
        pecho >&2 "Error parsing options!"
        exit 2
    fi

    eval set -- "$ARGS"

    while true; do
        case "$1" in
            -r|--release) release="$2"; shift 2 ;;
            -a|--arch) arch="$2"; shift 2 ;;
            -m|--minimal) minimal=true; shift ;;
            -h|--help) print_help; exit 0 ;;
            --) shift; break ;;
        esac
    done

    #
    # build!
    #

    bootstrap "$name" "$rootfs" "$release" "$arch"
    configure "$name" "$rootfs" "$release" "$minimal"
}

blueprint_cleanup () {
    local name="$1"
    local rootfs="$2"

    # clean up any debpkg artifacts
    make clean >/dev/null

    # clean up any dangling mounts
    chroot_umount "$rootfs" || true

    # destroy persistent lxc object
    if [ -d "/var/lib/lxc/${name}" ] ; then
        lxc-destroy -n "$name"
    fi
}

pecho "loading..."
