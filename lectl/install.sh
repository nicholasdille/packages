#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/sahsanu/lectl/releases/latest | \
    jq --raw-output '.tag_name' | \
    xargs -I{} sudo curl --location --fail --output ${TARGET}/bin/lectl https://raw.githubusercontent.com/sahsanu/lectl/{}/lectl
sudo chmod +x ${TARGET}/bin/lectl
