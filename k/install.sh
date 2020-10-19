#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

filename=$(mktemp)
github_find_latest_release rothgar/k | \
    github_resolve_assets | \
    github_select_asset_by_suffix _Linux_x86_64.tar.gz | \
    github_get_asset_download_url | \
    download_file \
    >"${filename}"

sudo tar -xz -f "${filename}" -C "${TARGET_BIN}" --strip-components=1 bin/k

sudo tar -xz -f "${filename}" -C "${TARGET_COMPLETION}" --strip-components=2 completions/bash/k
sudo mv "${TARGET_COMPLETION}/k" "${TARGET_COMPLETION}/k.sh"

rm "${filename}"
