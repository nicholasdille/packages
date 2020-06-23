#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/xetys/hetzner-kube/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux-amd64")) | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/hetzner-kube
sudo chmod +x ${TARGET}/bin/hetzner-kube

sudo mkdir -p ${TARGET}/etc/bash_completion.d
hetzner-kube completion bash | sudo tee ${TARGET}/etc/bash_completion.d/hetzner-kube.sh >/dev/null
sudo ln -sf ${TARGET}/etc/bash_completion.d/hetzner-kube.sh /etc/bash_completion.d/
