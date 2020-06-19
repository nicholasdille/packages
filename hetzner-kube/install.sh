#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/xetys/hetzner-kube/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux-amd64")) | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/hetzner-kube
sudo chmod +x ${TARGET}/bin/hetzner-kube
