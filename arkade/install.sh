#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo alexellis/arkade \
    --match name \
    --asset arkade \
    --type binary \
    --name arkade
