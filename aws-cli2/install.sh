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

tmpdir=$(mktemp -d)
echo "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${VERSION}.zip" | \
    download_file | \
    store_file aws-cli.zip "${tmpdir}"
unzip -o -d "${tmpdir}" "${tmpdir}/aws-cli.zip"
${SUDO} "${tmpdir}/aws/install" \
    --update \
    --install-dir "${TARGET_BASE}/aws-cli" \
    --bin-dir "${TARGET_BIN}"
rm -rf "${tmpdir}"
