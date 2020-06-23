#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/opencontainers/umoci/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "umoci.amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/umoci
sudo chmod +x ${TARGET}/bin/umoci
