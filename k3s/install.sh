#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl -s https://api.github.com/repos/rancher/k3s/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "k3s") | .browser_download_url' | \
    xargs sudo curl -Lfo ${TARGET}/bin/k3s
sudo chmod +x ${TARGET}/bin/k3s

