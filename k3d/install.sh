#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/rancher/k3d/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "k3d-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/k3d
sudo chmod +x ${TARGET}/bin/k3d

# k3d complete bash (version >= 3)
