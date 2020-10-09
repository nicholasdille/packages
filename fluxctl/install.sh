#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo fluxcd/flux \
    --match name \
    --asset fluxctl_linux_amd64 \
    --type binary \
    --name fluxctl
