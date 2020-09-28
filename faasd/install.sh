#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/openfaas/faasd/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "faasd") | .browser_download_url' | \
    xargs sudo curl --silent --location --fail --output ${TARGET}/bin/faasd
sudo chmod +x ${TARGET}/bin/faasd
