#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo stephenc/envsub \
    --match name \
    --asset envsub \
    --type binary \
    --name envsub
