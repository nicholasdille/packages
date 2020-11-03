#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo marcosnils/bin \
    --match suffix \
    --asset _Linux_x86_64 \
    --type binary \
    --name bin
