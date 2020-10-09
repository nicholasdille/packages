#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release cloudflare/cfssl | \
    github_resolve_assets | \
    github_select_asset_by_suffix _linux_amd64 | \
    run_tasks \
        "\
            github_select_asset_by_prefix cfssl_ | \
            github_get_asset_download_url | \
            download_file | \
            store_file cfssl | \
            make_executable \
        " \
        "\
            github_select_asset_by_prefix cfssljson_ | \
            github_get_asset_download_url | \
            download_file | \
            store_file cfssljson | \
            make_executable \
        "
