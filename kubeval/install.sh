#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo instrumenta/kubeval \
    --match name \
    --asset kubeval-linux-amd64.tar.gz \
    --type tarball \
    --include kubeval
