#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

install_python_module yamllint

mkdir -p "${HOME}/.config/yamllint"
curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file yamllint yamllint.yaml | \
    store_file config "${HOME}/.config/yamllint"
