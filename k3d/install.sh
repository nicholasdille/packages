#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/rancher/k3d/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "k3d-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/k3d
sudo chmod +x ${TARGET}/bin/k3d

sudo mkdir -p ${TARGET}/etc/bash_completion.d
k3d completion bash | sudo tee ${TARGET}/etc/bash_completion.d/k3d.sh >/dev/null
sudo ln -sf ${TARGET}/etc/bash_completion.d/k3d.sh /etc/bash_completion.d/
