#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

require gvm

TAG=$(
    github_get_tags golang/go | \
        jq 'map(select(.ref | startswith("refs/tags/go")))' | \
        github_select_latest_tag
)

export GVM_ROOT="${HOME}/.gvm"
# shellcheck disable=SC1090
source "$GVM_ROOT/scripts/gvm-default"
gvm install "${TAG}" --binary

gvm list
