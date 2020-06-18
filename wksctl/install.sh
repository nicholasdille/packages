#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl -s https://api.github.com/repos/weaveworks/wksctl/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux-x86_64.tar.gz")) | .browser_download_url' | \
    xargs curl -Lf | \
    sudo tar -xzC ${TARGET}/bin/ wksctl