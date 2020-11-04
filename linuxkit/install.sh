#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo linuxkit/linuxkit \
    --match name \
    --asset linuxkit-linux-amd64 \
    --type binary \
    --name linuxkit
