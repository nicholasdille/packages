#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo charmbracelet/glow \
    --match suffix \
    --asset _linux_x86_64.tar.gz \
    --type tarball \
    --include glow
