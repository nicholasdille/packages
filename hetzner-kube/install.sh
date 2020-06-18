#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl -s https://api.github.com/repos/xetys/hetzner-kube/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux-amd64")) | .browser_download_url' | \
    xargs sudo curl -Lfo ${TARGET}/bin/hetzner-kube
sudo chmod +x ${TARGET}/bin/hetzner-kube
