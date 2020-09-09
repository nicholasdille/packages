#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/corneliusweig/rakkess/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "rakkess-amd64-linux.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ rakkess-amd64-linux
sudo mv ${TARGET}/bin/rakkess-amd64-linux ${TARGET}/bin/rakkess
