#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
check_docker
unlock_sudo

github_install \
    --repo AkihiroSuda/sshocker \
    --match name \
    --asset sshocker-Linux-x86_64 \
    --type binary \
    --name sshocker
