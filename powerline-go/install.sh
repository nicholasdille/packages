#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo justjanne/powerline-go \
    --match suffix \
    --asset -linux-amd64 \
    --type binary \
    --name powerline-go

mkdir -p "${HOME}/.local/etc"
curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file powerline-go theme.json | \
    store_file powerline-go-theme.json "${HOME}/.local/etc"

# shellcheck disable=SC2016
curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file powerline-go profile.d.powerline-go.sh | \
    TARGET_BIN="${TARGET_BIN}" envsubst '${TARGET_BIN}' | \
    store_file powerline-go.sh /etc/profile.d
