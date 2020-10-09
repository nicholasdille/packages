#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo mikefarah/yq \
    --match name \
    --asset yq_linux_amd64 \
    --type binary \
    --name yq
