#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --name direnv \
    --repo direnv/direnv \
    --match name \
    --asset direnv.linux-amd64 \
    --type binary

echo
echo "#############################################"
echo "### Now add the following to your ~/.bashrc:"
echo "###"
echo "eval \$(direnv hook bash)"
echo "#############################################"
echo
