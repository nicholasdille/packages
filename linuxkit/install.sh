#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/linuxkit/linuxkit/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "linuxkit-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --silent --location --fail --output ${TARGET}/bin/linuxkit
sudo chmod +x ${TARGET}/bin/linuxkit
