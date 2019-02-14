#!/bin/bash

mkdir -p out

parameters="-- --minimal"
if [ $# -gt 0 ]; then parameters="$@"; fi

docker build -t maruos/blueprints .
docker run --privileged --rm \
        -v /var/cache:/var/cache \
        -v "$(pwd)":/var/maru \
        -ti maruos/blueprints ${parameters}
