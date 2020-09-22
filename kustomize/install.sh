#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/kubernetes-sigs/kustomize/releases | \
    jq --raw-output 'map(select(.tag_name | startswith("kustomize/"))) | first | .assets[] | select(.name | endswith("_linux_amd64.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/

sudo mkdir -p ${TARGET}/etc/bash_completion.d
kustomize install-completion | sudo tee ${TARGET}/etc/bash_completion.d/kustomize.sh >/dev/null
sudo ln -sf ${TARGET}/etc/bash_completion.d/kustomize.sh /etc/bash_completion.d/
