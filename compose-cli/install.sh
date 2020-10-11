#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo docker/compose-cli \
    --match name \
    --asset docker-linux-amd64.tar.gz \
    --type tarball \
    --include com.docker.cli
