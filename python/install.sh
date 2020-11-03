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
${SUDO} "${PYENV_ROOT}/bin/pyenv" rehash

# shellcheck disable=SC2016
curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file python profile.d.python.sh | \
    PYENV_ROOT=${PYENV_ROOT} PYTHON_VERSION=${TAG#v} envsubst '${TARGET_BASE},${PYTHON_VERSION}' | \
    store_file python.sh /etc/profile.d
