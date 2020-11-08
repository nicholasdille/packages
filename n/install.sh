#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

TAG=$(
    github_find_latest_release tj/n | \
        jq --raw-output '.tag_name'
)

echo "https://github.com/tj/n/raw/${TAG}/bin/n" | \
    download_file | \
    store_file n | \
    make_executable

# shellcheck disable=SC2016
get_file "${PACKAGE}" profile.d.n.sh | \
    TARGET_BASE="${TARGET_BASE}" envsubst '${TARGET_BASE}' | \
    store_file n.sh /etc/profile.d
