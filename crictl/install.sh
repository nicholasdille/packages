#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl -s https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest | \
    jq --raw-output '.assets[] | select(.name | startswith("crictl-")) | select(.name | endswith("-linux-amd64.tar.gz")) | .browser_download_url' | \
    xargs curl -Lf | \
    sudo tar -xzC ${TARGET}/bin

# crictl completion bash
