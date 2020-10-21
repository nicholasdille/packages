#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/jgm/pandoc/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux-amd64.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    ${SUDO} tar -xzC ${TARGET} --strip-components=1
