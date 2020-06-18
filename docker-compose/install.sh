#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl --silent https://api.github.com/repos/docker/compose/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "docker-compose-Linux-x86_64") | .browser_download_url' | \
    xargs sudo curl -Lfo ${TARGET}/bin/docker-compose
sudo chmod +x ${TARGET}/bin/docker-compose
