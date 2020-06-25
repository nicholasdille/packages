#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

if curl -sf https://api.github.com/repos/stepro/kdo/releases/latest >/dev/null; then
    echo "ERROR: kdo has a stable release. Please update install.sh"
    exit 1
fi

curl -s https://api.github.com/repos/stepro/kdo/releases | \
    jq --raw-output '.[].tag_name' | \
    sort --version-sort --reverse | \
    head -n 1 | \
    xargs -I{} curl -s https://api.github.com/repos/stepro/kdo/releases/tags/{} | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux-amd64.tar.gz")) | .browser_download_url' | \
    xargs curl -Lf | \
    sudo tar -xzC ${TARGET}/bin/
