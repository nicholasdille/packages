#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/alexellis/arkade/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "arkade") | .browser_download_url' | \
    xargs sudo curl --silent --location --fail --output ${TARGET}/bin/arkade
sudo chmod +x ${TARGET}/bin/arkade
