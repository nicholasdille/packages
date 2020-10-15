#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release containerd/containerd | \
    github_resolve_assets | \
    github_select_asset_by_prefix containerd- | \
    github_select_asset_by_suffix -linux-amd64.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    sudo tar -xzC "${TARGET_BASE}"
