#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/k14s/imgpkg/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux-amd64")) | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/imgpkg
sudo chmod +x ${TARGET}/bin/imgpkg
