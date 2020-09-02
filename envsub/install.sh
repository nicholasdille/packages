#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/stephenc/envsub/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "envsub") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/envsub
sudo chmod +x ${TARGET}/bin/envsub
