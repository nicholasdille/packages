#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo alexellis/arkade \
    --match name \
    --asset arkade \
    --type binary \
    --name arkade
