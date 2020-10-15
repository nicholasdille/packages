#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo marcosnils/bin \
    --match suffix \
    --asset _Linux_x86_64 \
    --type binary \
    --name bin
