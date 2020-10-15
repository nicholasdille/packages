#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_get_releases moby/buildkit | \
    jq 'map(select(.tag_name | startswith("v"))) | .[0]' | \
    github_resolve_assets | \
    github_select_asset_by_suffix .linux-amd64.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    sudo tar -xzC "${TARGET_BASE}"

github_get_releases moby/buildkit | \
    jq --raw-output 'map(select(.tag_name | startswith("v"))) | .[0].tag_name' | \
    xargs -I{} sudo curl --location --fail https://raw.githubusercontent.com/moby/buildkit/{}/examples/buildctl-daemonless/buildctl-daemonless.sh | \
    store_file buildctl-daemonless.sh | \
    make_executable
