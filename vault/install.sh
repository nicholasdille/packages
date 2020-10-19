#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

TAG=$(
    github_get_tags hashicorp/vault | \
    github_select_latest_tag
)

tmpdir=$(mktemp -d)
echo "https://releases.hashicorp.com/vault/${TAG#v}/vault_${TAG#v}_linux_amd64.zip" | \
    download_file | \
    store_file "vault.zip" "${tmpdir}"
unzip_file "${tmpdir}/vault.zip"
rm -f "${tmpdir}/vault.zip"
rmdir "${tmpdir}"
