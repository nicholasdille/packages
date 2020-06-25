#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/hetznercloud/cli/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "hcloud-linux-amd64.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ hcloud

# hcloud completion bash
