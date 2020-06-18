#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl --silent https://api.github.com/repos/mikefarah/yq/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "yq_linux_amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/yq
sudo chmod +x ${TARGET}/bin/yq
