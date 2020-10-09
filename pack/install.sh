#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo buildpacks/pack \
    --match suffix \
    --asset -linux.tgz \
    --type tarball \
    --include pack
