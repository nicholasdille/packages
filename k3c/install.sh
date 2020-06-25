#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl -s https://api.github.com/repos/rancher/k3c/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "k3c-linux-amd64") | .browser_download_url' | \
    xargs sudo curl -sLfo ${TARGET}/bin/k3c
sudo chmod +x ${TARGET}/bin/k3c
