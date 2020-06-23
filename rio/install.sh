#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/rancher/rio/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "rio-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --silent --location --fail --output ${TARGET}/bin/rio
sudo chmod +x ${TARGET}/bin/rio
