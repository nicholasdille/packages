#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo rancher/k3d \
    --match name \
    --asset k3d-linux-amd64 \
    --type binary \
    --name k3d

k3d completion bash | \
    store_completion k3d
