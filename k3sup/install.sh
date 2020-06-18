#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl --silent https://api.github.com/repos/alexellis/k3sup/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "k3sup") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/k3sup
sudo chmod +x ${TARGET}/bin/k3sup
