#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

TAG=$(
    github_find_latest_release wslutilities/wslu | \
    jq --raw-output '.tag_name'
)

git clone https://github.com/wslutilities/wslu "${temporary_directory}"
git checkout "${TAG}"
${SUDO} PREFIX=/usr/local make all install
