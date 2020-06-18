#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl --silent https://api.github.com/repos/superbrothers/ksort/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "ksort-linux-amd64.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC /usr/local/bin/ ksort
