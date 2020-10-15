#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo openfaas/faas-cli \
    --match name \
    --asset faas-cli \
    --type binary \
    --name faas-cli
