#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo superbrothers/ksort \
    --match name \
    --asset ksort-linux-amd64.tar.gz \
    --type tarball \
    --include ksort
