#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

mkdir --parents ~/.docker/cli-plugins
curl --silent https://api.github.com/repos/docker/buildx/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith(".linux-amd64")) | .browser_download_url' | \
    xargs curl --location --fail --output ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx
