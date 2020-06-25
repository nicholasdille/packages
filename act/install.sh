#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl -s https://api.github.com/repos/nektos/act/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "act_Linux_x86_64.tar.gz") | .browser_download_url' | \
    xargs curl -Lf | \
    sudo tar -xzC ${TARGET}/bin/ act
