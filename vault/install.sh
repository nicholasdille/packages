#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

TAG=$(
    github_get_tags hashicorp/vault | \
    github_select_latest_tag
)

echo "https://releases.hashicorp.com/vault/${TAG#v}/vault_${TAG#v}_linux_amd64.zip" | \
    download_file | \
    store_file "vault.zip" "${temporary_directory}"
unzip_file "${temporary_directory}/vault.zip"
${SUDO} mv vault "${TARGET_BIN}"
