#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/weaveworks/wksctl/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux-x86_64.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ wksctl