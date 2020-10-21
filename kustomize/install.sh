#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/kubernetes-sigs/kustomize/releases | \
    jq --raw-output 'map(select(.tag_name | startswith("kustomize/"))) | first | .assets[] | select(.name | endswith("_linux_amd64.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    ${SUDO} tar -xzC ${TARGET}/bin/

echo "complete -C ${TARGET}/bin/kustomize kustomize" | \
    store_completion kustomize
