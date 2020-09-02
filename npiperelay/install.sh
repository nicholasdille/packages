#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/NZSmartie/npiperelay/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "npiperelay.exe") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/npiperelay.exe
sudo chmod +x ${TARGET}/bin/npiperelay.exe
