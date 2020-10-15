#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release mike-engel/jwt-cli | \
    github_resolve_assets | \
    github_select_asset_by_suffix -linux.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    untar_file --strip-components=2 jwt-cli
