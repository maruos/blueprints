FROM debian:buster

RUN dpkg --add-architecture i386 \
&& apt-get update && apt-get install -y \
    binfmt-support \
    debootstrap \
    fakeroot \
    git \
    lxc \
    make \
    qemu-user-static:i386 \
    ubuntu-archive-keyring \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

ENV MARU_WORKSPACE /var/maru
RUN mkdir -p ${MARU_WORKSPACE}
WORKDIR ${MARU_WORKSPACE}

ENTRYPOINT ["./build.sh"]
