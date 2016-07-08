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

    # make sure we have a mirror for installing packages
    cat >> "${rootfs}/etc/apt/sources.list" <<EOF
    deb http://httpredir.debian.org/debian jessie main
EOF

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

plugin_go () {
    local name="$1"
    local rootfs="$2"
    local arch="${3:-armhf}"

    bootstrap "$name" "$rootfs" "$arch"
    configure "$name" "$rootfs"
}

pecho "loading..."
