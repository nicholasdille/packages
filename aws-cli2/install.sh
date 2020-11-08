#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

VERSION=$(
    get_package_definition | \
        jq --raw-output '.version.latest'
)

echo "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${VERSION}.zip" | \
    download_file | \
    store_file aws-cli.zip "${temporary_directory}"
unzip -o -d "${temporary_directory}" "${temporary_directory}/aws-cli.zip"
${SUDO} "${temporary_directory}/aws/install" \
    --update \
    --install-dir "${TARGET_BASE}/aws-cli" \
    --bin-dir "${TARGET_BIN}"
