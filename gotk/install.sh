#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo fluxcd/toolkit \
    --match suffix \
    --asset _linux_amd64.tar.gz \
    --type tarball \
    --include gotk

gotk completion bash | \
    store_completion gotk
