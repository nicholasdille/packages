#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/docker/docker-ce/releases/latest | \
    jq --raw-output '.name' | \
    xargs -I{} curl --location --fail https://download.docker.com/linux/static/stable/x86_64/docker-{}.tgz | \
    sudo tar -xzC ${TARGET}/bin/ --strip-components=1

# https://github.com/docker/cli/blob/master/contrib/completion/bash/docker
