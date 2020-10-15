#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo cyberark/kubeletctl \
    --match name \
    --asset kubeletctl_linux_amd64 \
    --type binary \
    --name kubeletctl
