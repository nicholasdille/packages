#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo tianon/gosu \
    --match name \
    --asset gosu-amd64 \
    --type binary \
    --name gosu
