#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_find_latest_release rothgar/k | \
    github_resolve_assets | \
    github_select_asset_by_suffix _Linux_x86_64.tar.gz | \
    github_get_asset_download_url | \
    download_file \
    >"${temporary_directory}/k.tar.gz"

${SUDO} tar -xz -f "${temporary_directory}/k.tar.gz" -C "${TARGET_BIN}" --strip-components=1 bin/k

${SUDO} tar -xz -f "${temporary_directory}/k.tar.gz" -C "${TARGET_COMPLETION}" --strip-components=2 completions/bash/k
${SUDO} mv "${TARGET_COMPLETION}/k" "${TARGET_COMPLETION}/k.sh"
