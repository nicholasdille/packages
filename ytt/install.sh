#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo k14s/ytt \
    --match suffix \
    --asset -linux-amd64 \
    --type binary \
    --name ytt
