#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "kubeseal-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/kubeseal
sudo chmod +x ${TARGET}/bin/kubeseal
