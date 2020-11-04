#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

if curl --silent --fail https://api.github.com/repos/stepro/kdo/releases/latest >/dev/null; then
    echo "ERROR: kdo has a stable release. Please update install.sh"
    exit 1
fi

check_installed_version
unlock_sudo

github_get_releases stepro/kdo | \
    jq --raw-output '.[].tag_name' | \
    sort --version-sort --reverse | \
    head -n 1 | \
    xargs -I{} curl --silent https://api.github.com/repos/stepro/kdo/releases/tags/{} | \
    github_resolve_assets | \
    github_select_asset_by_suffix -linux-amd64.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    untar_file kdo
