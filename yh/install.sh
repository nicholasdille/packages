#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo andreazorzetto/yh \
    --match name \
    --asset yh-linux-amd64.zip \
    --type zip \
    --include yh
