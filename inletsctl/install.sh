#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release inlets/inletsctl | \
    github_resolve_assets | \
    github_select_asset_by_name inletsctl.tgz | \
    download_file | \
    sudo tar -xzC ${TARGET_BASE} bin/inletsctl
