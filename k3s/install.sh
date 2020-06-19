#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/rancher/k3s/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "k3s") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/k3s
sudo chmod +x ${TARGET}/bin/k3s

