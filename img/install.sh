#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo genuinetools/img \
    --match name \
    --asset img-linux-amd64 \
    --type binary \
    --name img
