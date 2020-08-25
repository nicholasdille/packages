#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/kubernetes-sigs/krew/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "krew.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ ./krew-linux_amd64
sudo mv ${TARGET}/bin/krew-linux_amd64 ${TARGET}/bin/krew
krew update
krew install \
    access-matrix \
    advise-psp \
    debug \
    doctor \
    exec-as \
    get-all \
    images \
    neat \
    net-forward \
    node-shell \
    rbac-lookup \
    rbac-view \
    resource-capacity \
    score \
    sniff \
    sort-manifests \
    status \
    sudo \
    tmux-exec \
    tree \
    view-allocations \
    who-can \
    whoami
