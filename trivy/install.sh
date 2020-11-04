#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo aquasecurity/trivy \
    --match suffix \
    --asset _Linux-64bit.tar.gz \
    --type tarball \
    --include trivy

if [[ ! -d "${HOME}/.cache/trivy" ]]; then
    trivy image --download-db-only
fi
