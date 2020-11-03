#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

require rbenv
# shellcheck disable=SC1091
source /etc/profile.d/rbenv.sh

TAG=$(
    github_get_tags ruby/ruby | \
        jq --raw-output '.[].ref' | \
        cut -d/ -f3 | \
        grep -E "^v[0-9]+_[0-9]+_[0-9]+$" | \
        tr '_' '.' | \
        sort -V -r | \
        head -n 1
)

docker run --rm --name rbenv \
    --env RBENV_ROOT \
    --env PATH \
    --volume "${RBENV_ROOT}:${RBENV_ROOT}" \
    rbenv \
    rbenv install "${TAG#v}" --skip-existing
${SUDO} bash -c "source /etc/profile.d/rbenv.sh; rbenv rehash"
${SUDO} bash -c "source /etc/profile.d/rbenv.sh; rbenv global ${TAG#v}"
