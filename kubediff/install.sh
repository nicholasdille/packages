#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

clean() {
    rm -rf "${MKTEMP}"
}
trap clean EXIT

check_installed_version
unlock_sudo
require python

MKTEMP=$(mktemp --directory)
git clone https://github.com/weaveworks/kubediff "${MKTEMP}"
cd "${MKTEMP}"
${SUDO} pip3 install .
${SUDO} pip3 install -r requirements.txt

# shellcheck disable=SC2002
cat kubediff | \
    sed -E 's|(#!/usr/bin/env python)|\13|' | \
    store_file kubediff
