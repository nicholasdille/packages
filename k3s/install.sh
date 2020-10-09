#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo rancher/k3s \
    --match name \
    --asset k3s \
    --type binary \
    --name k3s

