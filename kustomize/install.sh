#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_get_releases kubernetes-sigs/kustomize | \
    jq --raw-output 'map(select(.tag_name | startswith("kustomize/"))) | first' | \
    github_resolve_assets | \
    github_select_asset_by_suffix _linux_amd64.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    untar_file kustomize

echo "complete -C ${TARGET}/bin/kustomize kustomize" | \
    store_completion kustomize
