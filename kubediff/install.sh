#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo
require python

git clone https://github.com/weaveworks/kubediff "${temporary_directory}"
${SUDO} pip3 install .
${SUDO} pip3 install -r requirements.txt

# shellcheck disable=SC2002
cat kubediff | \
    sed -E 's|(#!/usr/bin/env python)|\13|' | \
    store_file kubediff
