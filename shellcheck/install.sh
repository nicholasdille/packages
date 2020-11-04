#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_find_latest_release koalaman/shellcheck | \
    github_resolve_assets | \
    github_select_asset_by_suffix .linux.x86_64.tar.xz | \
    github_get_asset_download_url | \
    download_file | \
    ${SUDO} tar -xJC "${TARGET_BIN}" --strip-components 1 --wildcards "*/shellcheck"
