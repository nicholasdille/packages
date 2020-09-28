#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/openfaas/faas-cli/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "faas-cli") | .browser_download_url' | \
    xargs sudo curl --silent --location --fail --output ${TARGET}/bin/faas-cli
sudo chmod +x ${TARGET}/bin/faas-cli
