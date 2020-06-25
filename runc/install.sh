#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl -s https://api.github.com/repos/opencontainers/runc/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "runc.amd64") | .browser_download_url' | \
    xargs sudo curl -Lfo ${TARGET}/bin/runc
sudo chmod +x ${TARGET}/bin/runc
