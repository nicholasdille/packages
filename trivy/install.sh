#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl --silent https://api.github.com/repos/aquasecurity/trivy/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("_Linux-64bit.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin trivy

# Download databases to avoid delay
if [[ ! -d ~/.cache/trivy ]]; then
    trivy --refresh
fi
