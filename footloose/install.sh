#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo weaveworks/footloose \
    --match suffix \
    --asset -linux-x86_64 \
    --type binary \
    --name footloose
