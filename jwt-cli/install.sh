#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo mike-engel/jwt-cli \
    --match suffix \
    --asset -linux.tar.gz \
    --type tarball \
    --include jwt
