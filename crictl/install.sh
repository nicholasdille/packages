#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl -s https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest | \
    jq --raw-output '.assets[] | select(.name | startswith("crictl-")) | select(.name | endswith("-linux-amd64.tar.gz")) | .browser_download_url' | \
    xargs curl -Lf | \
    sudo tar -xzC ${TARGET}/bin

sudo mkdir -p ${TARGET}/etc/bash_completion.d
crictl completion bash | sudo tee ${TARGET}/etc/bash_completion.d/crictl.sh >/dev/null
sudo ln -s ${TARGET}/etc/bash_completion.d/crictl.sh /etc/bash_completion.d/
