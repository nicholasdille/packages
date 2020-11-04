#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo fluxcd/flux \
    --match name \
    --asset fluxctl_linux_amd64 \
    --type binary \
    --name fluxctl

fluxctl completion bash | \
    store_completion fluxctl
