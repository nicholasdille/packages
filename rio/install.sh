#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo rancher/rio \
    --match name \
    --asset rio-linux-amd64 \
    --type binary \
    --name rio
