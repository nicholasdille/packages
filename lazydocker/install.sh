#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo jesseduffield/lazydocker \
    --match suffix \
    --asset _Linux_x86_64.tar.gz \
    --type tarball \
    --include lazydocker
