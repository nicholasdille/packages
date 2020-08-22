#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/mike-engel/jwt-cli/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin --strip-components=2
