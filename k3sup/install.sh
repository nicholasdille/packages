#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo alexellis/k3sup \
    --match name \
    --asset k3sup \
    --type binary \
    --name k3sup
