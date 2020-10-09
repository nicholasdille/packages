#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo opencontainers/umoci \
    --match name \
    --asset umoci.amd64 \
    --type binary \
    --name umoci
