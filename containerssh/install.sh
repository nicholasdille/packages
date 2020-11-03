#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_get_releases containerssh/containerssh | \
    jq '.[0]' | \
    github_resolve_assets | \
    github_select_asset_by_suffix _linux_amd64.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    untar_file containerssh containerssh-auditlog-decoder containerssh-testauthconfigserver
