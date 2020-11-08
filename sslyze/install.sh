#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

install_python_module sslyze

get_file "${PACKAGE}" profile.d.sslyze.sh | \
    TARGET_BASE=${TARGET_BASE} envsubst '${TARGET_BASE}' | \
    store_file sslyze.sh /etc/profile.d/
