#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl --silent https://api.github.com/repos/docker/docker-ce/releases/latest | \
    jq --raw-output '.name' | \
    xargs -I{} curl -Lf https://download.docker.com/linux/static/stable/x86_64/docker-{}.tgz | \
    sudo tar -xzC ${TARGET}/bin/ --strip-components=1
