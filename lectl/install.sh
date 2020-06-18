#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl -s https://api.github.com/repos/sahsanu/lectl/releases/latest | \
    jq --raw-output '.tag_name' | \
    xargs -I{} sudo curl -Lfo ${TARGET}/bin/lectl https://raw.githubusercontent.com/sahsanu/lectl/{}/lectl
sudo chmod +x ${TARGET}/bin/lectl
