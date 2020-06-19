#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/buildpacks/pack/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux.tgz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/
