#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/argoproj/argo-cd/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "argocd-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/argocd
sudo chmod +x ${TARGET}/bin/argocd

sudo mkdir -p ${TARGET}/etc/bash_completion.d
argocd completion bash | sudo tee ${TARGET}/etc/bash_completion.d/argocd.sh >/dev/null
sudo ln -sf ${TARGET}/etc/bash_completion.d/argocd.sh /etc/bash_completion.d/
