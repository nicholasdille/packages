#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release nektos/act | \
    github_select_asset_by_suffix _Linux_x86_64.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    untar_file act
