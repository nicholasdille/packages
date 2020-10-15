#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo rancher/k3c \
    --match name \
    --asset k3c-linux-amd64 \
    --type binary \
    --name k3c
