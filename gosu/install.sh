#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl -s https://api.github.com/repos/tianon/gosu/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "gosu-amd64") | .browser_download_url' | \
    xargs sudo curl -Lfo ${TARGET}/bin/gosu
sudo chmod +x ${TARGET}/bin/gosu
