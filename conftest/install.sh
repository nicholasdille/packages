#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo open-policy-agent/conftest \
    --match suffix \
    --asset _Linux_x86_64.tar.gz \
    --type tarball \
    --include conftest