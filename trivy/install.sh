#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/aquasecurity/trivy/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("_Linux-64bit.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin trivy

if [[ ! -d ~/.cache/trivy ]]; then
    trivy --refresh
fi
