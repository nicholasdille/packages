#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/derailed/k9s/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "k9s_Linux_x86_64.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ k9s
