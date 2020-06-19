#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/corneliusweig/rakkess/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "rakkess-amd64-linux.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC /usr/local/bin/ rakkess-amd64-linux
sudo mv /usr/local/bin/rakkess-amd64-linux /usr/local/bin/rakkess
