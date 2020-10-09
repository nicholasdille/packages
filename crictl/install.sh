#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release kubernetes-sigs/cri-tools | \
    github_resolve_assets | \
    run_filters \
        "github_select_asset_by_prefix crictl-" \
        "github_select_asset_by_suffix -linux-amd64.tar.gz" | \
    github_get_asset_download_url | \
    download_file | \
    untar_file crictl

crictl completion bash | \
    store_completion crictl
