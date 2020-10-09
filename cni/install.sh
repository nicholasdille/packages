#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

sudo mkdir -p /opt/cni/bin
github_find_latest_release containernetworking/plugins | \
    github_resolve_assets | \
    run_filters \
        "github_select_asset_by_prefix cni-plugins-linux-amd64" \
        "github_select_asset_by_suffix .tgz" | \
    github_get_asset_download_url | \
    download_file | \
    sudo tar -xzC /opt/cni/bin/
