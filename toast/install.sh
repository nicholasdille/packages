#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo stepchowfun/toast \
    --match name \
    --asset toast-x86_64-unknown-linux-gnu \
    --type binary \
    --name toast
