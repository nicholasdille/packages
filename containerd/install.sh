#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl -s https://api.github.com/repos/containerd/containerd/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith(".linux-amd64.tar.gz")) | .browser_download_url' | \
    xargs curl -Lf | \
    sudo tar -xzC ${TARGET}
