#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --name bin \
    --repo marcosnils/bin \
    --match suffix \
    --asset _Linux_x86_64 \
    --type binary
