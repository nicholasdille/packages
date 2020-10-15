#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --name docker-compose \
    --repo docker/compose \
    --match name \
    --asset docker-compose-Linux-x86_64 \
    --type binary

sudo mkdir -p "${TARGET}/etc/bash_completion.d"
github_find_latest_release docker/compose | \
    jq --raw-output '.tag_name' | \
    xargs -I{} curl --location --fail https://github.com/docker/compose/raw/{}/contrib/completion/bash/docker-compose | \
    store_completion docker-compose
