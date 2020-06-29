#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/instrumenta/kubeval/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "kubeval-linux-amd64.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin kubeval
