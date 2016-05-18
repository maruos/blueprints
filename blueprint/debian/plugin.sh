PLUGIN_NAME="DEBIAN"

# tweaks to upstream, must be absolute path
LXC_TEMPLATE_OVERRIDE="$(pwd)/lxc/templates/debian.sh"
CHROOT_SCRIPT="chroot-configure.sh"

pecho () {
    echo "[ $PLUGIN_NAME ] $1"
}

bootstrap () {
    local name="$1"
    local dir="$2"
    local arch="${3:-armhf}"

    pecho "bootstrapping rootfs..."
    lxc-create -t "$LXC_TEMPLATE_OVERRIDE" -n "$name" --dir "$dir" -- -a "$arch"
}

configure () {
    local name="$1"
    local dir="$2"

    export DEBIAN_FRONTEND=noninteractive
    export DEBCONF_NONINTERACTIVE_SEEN=true
    export LC_ALL=C
    export LANGUAGE=C
    export LANG=C

    pecho "building maru debpkg..."
    make
    cp maru*.deb "${ROOTFS_DIR}/tmp"
    cp "$CHROOT_SCRIPT" "${ROOTFS_DIR}/tmp"

    pecho "configuring rootfs..."
    chroot "$ROOTFS_DIR" bash -c "cd /tmp && ./${CHROOT_SCRIPT}"
}

plugin_go () {
    local name="$1"
    local dir="$2"
    local arch="${3:-armhf}"

    bootstrap "$name" "$dir" "$arch"
    configure "$name" "$dir"
}

pecho "loading..."
