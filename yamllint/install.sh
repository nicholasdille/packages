#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

install_python_module yamllint

curl --silent --output "${HOME}/.config/yamllint/config" https://pkg.dille.io/yamllint/yamllint.yaml
