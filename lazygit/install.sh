#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo jesseduffield/lazygit \
    --match suffix \
    --asset _Linux_x86_64.tar.gz \
    --type tarball \
    --include lazygit
