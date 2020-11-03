#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

require pyenv

TAG=$(
    github_get_tags python/cpython | \
        jq -r '.[].ref' | \
        cut -d/ -f3 | \
        grep -E "^v[0-9]+\.[0-9]+\.[0-9]+$" | \
        sort -V -r | \
        head -n 1
)

export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"
docker run --rm --name pyenv \
    --env PYENV \
    --env HOME \
    --env PATH \
    --volume "${HOME}:${HOME}" \
    --workdir "${HOME}" \
    --user "$(id -u):$(id -g)" \
    pyenv \
    pyenv install "${TAG#v}" --skip-existing
pyenv rehash

echo
echo "#############################################"
echo "### Now add the following to your ~/.bashrc:"
echo "###"
echo "export PATH=\${HOME}/.pyenv/versions/${TAG#v}/bin:\${PATH}"
echo "#############################################"
echo
