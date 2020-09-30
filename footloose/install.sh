#!/bin/bash

set -o errexit

#source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)
source ~/private/packages/.scripts/source.sh

unlock_sudo

github_find_latest_release weaveworks/footloose | \
    github_select_asset_by_suffix -linux-x86_64 | \
    github_get_asset_download_url | \
    download_file | \
    store_file footloose

make_executable footloose
