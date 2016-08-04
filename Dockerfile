FROM debian:latest

RUN apt-get update && apt-get install -y \
    binfmt-support \
    debootstrap \
    fakeroot \
    git \
    lxc \
    make \
    qemu \
    qemu-user-static \
    ubuntu-archive-keyring \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

ENV MARU_WORKSPACE /var/maru
RUN mkdir -p ${MARU_WORKSPACE}
WORKDIR ${MARU_WORKSPACE}
COPY . ${MARU_WORKSPACE}

CMD ["./build.sh", "-b", "debian", "-n", "jessie"]
