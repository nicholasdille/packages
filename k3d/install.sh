#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl --silent https://api.github.com/repos/rancher/k3d/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "k3d-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/k3d
sudo chmod +x ${TARGET}/bin/k3d
