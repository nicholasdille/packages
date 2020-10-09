#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo estesp/manifest-tool \
    --match name \
    --asset manifest-tool-linux-amd64 \
    --type binary \
    --name manifest-tool
