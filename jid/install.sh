#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo simeji/jid \
    --match name \
    --asset jid_linux_amd64.zip \
    --type zip \
    --include jid
