#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo norouter/norouter \
    --match name \
    --asset norouter-Linux-x86_64 \
    --type binary \
    --name norouter
