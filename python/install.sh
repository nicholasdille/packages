#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

require pyenv
# shellcheck disable=SC1091
source /etc/profile.d/pyenv.sh

TAG=$(
    github_get_tags python/cpython | \
        jq -r '.[].ref' | \
        cut -d/ -f3 | \
        grep -E "^v[0-9]+\.[0-9]+\.[0-9]+$" | \
        sort -V -r | \
        head -n 1
)

docker run --rm --name pyenv \
    --env PYENV_ROOT \
    --env PATH \
    --volume "${PYENV_ROOT}:${PYENV_ROOT}" \
    pyenv \
    pyenv install "${TAG#v}" --skip-existing
${SUDO} bash -c "source /etc/profile.d/pyenv.sh; ${PYENV_ROOT}/bin/pyenv rehash"
${SUDO} bash -c "source /etc/profile.d/pyenv.sh; ${PYENV_ROOT}/bin/pyenv global ${TAG#v}"
