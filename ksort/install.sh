#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/superbrothers/ksort/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "ksort-linux-amd64.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC /usr/local/bin/ ksort
