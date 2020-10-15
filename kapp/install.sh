#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo k14s/kapp \
    --match suffix \
    --asset -linux-amd64 \
    --type binary \
    --name kapp
