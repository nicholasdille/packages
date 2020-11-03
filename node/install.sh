#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

require n
# shellcheck disable=SC1091
source /etc/profile.d/n.sh

${SUDO} -E n lts
