#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/mikefarah/yq/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "yq_linux_amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/yq
sudo chmod +x ${TARGET}/bin/yq
