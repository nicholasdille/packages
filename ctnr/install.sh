#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl -s https://api.github.com/repos/mgoltzsche/ctnr/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "ctnr-linux-amd64") | .browser_download_url' | \
    xargs sudo curl -sLfo ${TARGET}/bin/ctnr
sudo chmod +x ${TARGET}/bin/ctnr
