#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | \
    jq --raw-output '
        .assets[]
        | select(.name | startswith("kubectx"))
        | select(.name | endswith("_linux_x86_64.tar.gz"))
        | .browser_download_url
        '| \
    xargs curl -Lf | \
    sudo tar -xzC ${TARGET}/bin/ kubectx
