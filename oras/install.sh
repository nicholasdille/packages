#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/deislabs/oras/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("_linux_amd64.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ oras
