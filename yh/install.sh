#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/andreazorzetto/yh/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "yh-linux-amd64.zip") | .browser_download_url' | \
    xargs curl --location --fail --output /tmp/yh-linux-amd64.zip
sudo unzip -o -d /usr/local/bin /tmp/yh-linux-amd64.zip
rm -f /tmp/yh-linux-amd64.zip
