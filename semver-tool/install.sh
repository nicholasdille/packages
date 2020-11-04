#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

echo "https://github.com/fsaintjacques/semver-tool/raw/master/src/semver" | \
    download_file | \
    store_file semver | \
    make_executable
