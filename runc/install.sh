#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo opencontainers/runc \
    --match name \
    --asset runc.amd64 \
    --type binary \
    --name runc
