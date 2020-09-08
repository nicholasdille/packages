#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/simeji/jid/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "jid_linux_amd64.zip") | .browser_download_url' | \
    xargs curl --location --fail --remote-name
sudo unzip -d /usr/local/bin/ jid_linux_amd64.zip
rm jid_linux_amd64.zip
