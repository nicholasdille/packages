#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

# shellcheck disable=SC2154
docker create -i --name "${container_name}" ubuntu bash -xe

github_find_latest_release jonas/tig | \
    github_resolve_assets | \
    github_select_asset_by_suffix .tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    gunzip_file | \
    docker cp - "${container_name}:/"

docker start -i "${container_name}" <<EOF
apt-get update
apt-get -y install --no-install-recommends curl jq gcc ncurses-dev make
cd tig-*
./configure
make prefix=/usr/local
make install prefix=/usr/local
EOF
extract_file_from_container /usr/local/bin/tig
