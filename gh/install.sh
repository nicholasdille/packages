#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release cli/cli | \
    github_resolve_assets | \
    github_select_asset_by_suffix _linux_amd64.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    ${SUDO} tar -xzC "${TARGET}/bin/" --wildcards --strip-components=2 "*/bin/gh"

gh completion | \
    store_completion gh
