#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --name direnv \
    --repo direnv/direnv \
    --match name \
    --asset direnv.linux-amd64 \
    --type binary

get_file direnv profile.d.direnv.sh | \
    store_file direnv.sh /etc/profile.d
