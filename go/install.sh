#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
check_docker
unlock_sudo

require gvm

TAG=$(
    github_get_tags golang/go | \
        jq 'map(select(.ref | startswith("refs/tags/go")))' | \
        github_select_latest_tag
)

${SUDO} bash -c "source /etc/profile.d/gvm.sh; gvm install \"${TAG}\" --binary"

# shellcheck disable=SC2016
curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file "${PACKAGE}" profile.d.go.sh | \
    TARGET_BASE="${TARGET_BASE}" GO_VERSION="${TAG}" envsubst '${TARGET_BASE},${GO_VERSION}' | \
    store_file go.sh /etc/profile.d
