#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo corneliusweig/rakkess \
    --match name \
    --asset rakkess-amd64-linux.tar.gz \
    --type tarball \
    --include rakkess-amd64-linux
rename_file rakkess-amd64-linux rakkess
