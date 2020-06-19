#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/ahmetb/kubectx/releases/latest | \
    jq --raw-output '
        .assets[]
        | select(.name | startswith("kubectx"))
        | select(.name | endswith("_linux_x86_64.tar.gz"))
        | .browser_download_url
        '| \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ kubectx
