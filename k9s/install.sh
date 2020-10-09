#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo derailed/k9s \
    --match name \
    --asset k9s_Linux_x86_64.tar.gz \
    --type tarball \
    --include k9s
