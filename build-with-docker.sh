#!/bin/bash

mkdir -p out

parameters="-- --minimal"
if [ $# -gt 0 ]; then parameters="$@"; fi

arch=armhf
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--arch)
	    arch="$2"
	    shift 2
	    ;;
	--)
	    shift
	    ;;
	*)
	    echo "${1}"
	    if [ -n "$2" ]; then
                shift 2
	    else
	        shift
	    fi
	    ;;
    esac
done
echo "Arch ${arch}"

docker_image_name=maruos/blueprints/armhf
docker_file_name=Dockerfile.armhf
if [ "${arch}" == "arm64" ]; then
    echo "Build arm64 version rootfs"
    docker_image_name=maruos/blueprints/aarch64
    docker_file_name=Dockerfile.aarch64
else
    echo "Build armhf version rootfs"
    docker_image_name=maruos/blueprints/armhf
    docker_file_name=Dockerfile.armhf
fi
echo "Docker image name ${docker_image_name}"
echo "Docker file name ${docker_file_name}"
docker build -t ${docker_image_name} --file ${docker_file_name} .
docker run --privileged --rm \
        -v /var/cache:/var/cache \
        -v "$(pwd)":/var/maru \
        -ti ${docker_image_name} ${parameters}
