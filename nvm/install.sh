#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

TAG=$(
    github_find_latest_release nvm-sh/nvm | \
        jq --raw-output '.tag_name'
)

if ! test -d "${TARGET_BASE}/nvm"; then
    ${SUDO} git clone https://github.com/nvm-sh/nvm "${TARGET_BASE}/nvm"
fi
pushd "${HOME}/.nvm"
git checkout "${TAG}"
popd

# shellcheck disable=SC2016
curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file "${PACKAGE}" profile.d.nvm.sh | \
    TARGET_BASE="${TARGET_BASE}" envsubst '${TARGET_BASE}' | \
    store_file nvm.sh /etc/profile.d
