#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/direnv/direnv/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "direnv.linux-amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/direnv
sudo chmod +x ${TARGET}/bin/direnv

echo
echo "#############################################"
echo "### Now add the following to your ~/.bashrc:"
echo "###"
echo "eval \$(direnv hook bash)"
echo "#############################################"
echo
