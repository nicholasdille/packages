#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/inlets/inletsctl/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "inletsctl.tgz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET} bin/inletsctl
