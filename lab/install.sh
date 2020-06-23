#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/zaquestion/lab/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("_linux_amd64.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ lab

sudo mkdir -p ${TARGET}/etc/bash_completion.d
lab completion bash | sudo tee ${TARGET}/etc/bash_completion.d/lab.sh >/dev/null
sudo ln -s ${TARGET}/etc/bash_completion.d/lab.sh /etc/bash_completion.d/
