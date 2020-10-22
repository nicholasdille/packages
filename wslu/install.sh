#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

TAG=$(
    github_find_latest_release wslutilities/wslu | \
    jq --raw-output '.tag_name'
)

tmpdir=$(mktemp -d)

git clone https://github.com/wslutilities/wslu "${tmpdir}"
pushd "${tmpdir}"
git checkout "${TAG}"
${SUDO} PREFIX=/usr/local make all install
popd

rm -rf "${tmpdir}"
