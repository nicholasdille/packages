#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl -s https://api.github.com/repos/genuinetools/img/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "img-linux-amd64") | .browser_download_url' | \
    xargs sudo curl -sLfo ${TARGET}/bin/img
sudo chmod +x ${TARGET}/bin/img
