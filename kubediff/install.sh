#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

clean() {
    rm -rf "${MKTEMP}"
}
trap clean EXIT

unlock_sudo

MKTEMP=$(mktemp --directory)
git clone https://github.com/weaveworks/kubediff "${MKTEMP}"
cd "${MKTEMP}"
${SUDO} pip install .
${SUDO} pip install -r requirements.txt
${SUDO} cp kubediff "${TARGET_BIN}"
