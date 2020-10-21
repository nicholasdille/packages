#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

filename=$(mktemp)
github_find_latest_release sharkdp/bat | \
    github_resolve_assets | \
    github_select_asset_by_suffix -x86_64-unknown-linux-gnu.tar.gz | \
    github_get_asset_download_url | \
    download_file \
    >"${filename}"

${SUDO} tar -xz -f "${filename}" -C "${TARGET_BIN}" --wildcards --strip-components=1 "*/bat"
${SUDO} tar -xz -f "${filename}" -C "${TARGET_BASE}/man/man1" --wildcards --strip-components=1 "*/bat.1"

rm "${filename}"
