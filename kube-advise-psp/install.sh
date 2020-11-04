#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_find_latest_release sysdiglabs/kube-psp-advisor | \
    github_resolve_assets | \
    github_select_asset_by_suffix _linux_amd64.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    untar_file kubectl-advise-psp
rename_file kubectl-advise-psp kube-advise-psp
