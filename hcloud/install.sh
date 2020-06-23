#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/hetznercloud/cli/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "hcloud-linux-amd64.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ hcloud

sudo mkdir -p ${TARGET}/etc/bash_completion.d
hcloud completion bash | sudo tee ${TARGET}/etc/bash_completion.d/hcloud.sh >/dev/null
sudo ln -sf ${TARGET}/etc/bash_completion.d/hcloud.sh /etc/bash_completion.d/
