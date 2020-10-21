#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release github/hub | \
    github_resolve_assets | \
    run_tasks \
        "\
            github_select_asset_by_prefix hub-linux-amd64- | \
            github_get_asset_download_url | \
            download_file | \
            ${SUDO} tar -xzC ${TARGET_BASE} --wildcards --strip-components=1 */bin/hub
        " \
        "\
            github_select_asset_by_prefix hub-linux-amd64- | \
            github_get_asset_download_url | \
            download_file | \
            ${SUDO} tar -xzC ${TARGET_COMPLETION} --wildcards --strip-components=2 */etc/hub.bash_completion.sh
        "
