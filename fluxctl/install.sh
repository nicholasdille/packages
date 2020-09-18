#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/fluxcd/flux/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "fluxctl_linux_amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/fluxctl
sudo chmod +x ${TARGET}/bin/fluxctl
