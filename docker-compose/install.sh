#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/docker/compose/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "docker-compose-Linux-x86_64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/docker-compose
sudo chmod +x ${TARGET}/bin/docker-compose
