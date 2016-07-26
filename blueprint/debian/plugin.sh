PLUGIN_NAME="DEBIAN"

# tweaks to upstream, must be absolute path
LXC_TEMPLATE_OVERRIDE="$(pwd)/lxc/templates/debian.sh"
CHROOT_SCRIPT="chroot-configure.sh"

pecho () {
    echo "[ $PLUGIN_NAME ] $1"
}

bootstrap () {
    local name="$1"
    local rootfs="$2"
    local arch="${3:-armhf}"

    pecho "bootstrapping rootfs..."
    lxc-create -t "$LXC_TEMPLATE_OVERRIDE" -n "$name" --dir "$rootfs" -- -a "$arch"
}

configure () {
    local name="$1"
    local rootfs="$2"

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

    # make sure we have a mirror for installing packages
    cat >> "${rootfs}/etc/apt/sources.list" <<EOF
deb http://httpredir.debian.org/debian jessie main
EOF

    # disable any default.target
    # (LXC template symlinks to multi-user.target by default)
    SYSTEMD_DEFAULT_TARGET="${rootfs}/etc/systemd/system/default.target"
    if [ -e "$SYSTEMD_DEFAULT_TARGET" ] ; then
        rm "$SYSTEMD_DEFAULT_TARGET"
    fi

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
    chroot "$rootfs" bash -c "cd /tmp && ./${CHROOT_SCRIPT}"
}

blueprint_build () {
    local name="$1"
    local rootfs="$2"
    local arch="${3:-armhf}"

    bootstrap "$name" "$rootfs" "$arch"
    configure "$name" "$rootfs"
}

blueprint_cleanup () {
    local name="$1"
    local rootfs="$2"

    # destroy persistent lxc object
    if [ -d "/var/lib/lxc/${name}" ] ; then
        lxc-destroy -n "$name"
    fi
}

pecho "loading..."
