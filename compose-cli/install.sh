#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo
require docker

${SUDO} mv "${TARGET_BIN}/docker" "${TARGET_BIN}/com.docker.cli"

github_find_latest_release docker/compose-cli | \
    github_resolve_assets | \
    github_select_asset_by_name docker-linux-amd64.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    untar_file --strip-components=1 docker/docker
