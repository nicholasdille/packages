#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

install_python_module termtosvg

cat <<EOF
Record: termtosvg -t progress_bar myfile.svg
Convert from asciinema: termtosvg render test.cast test.svg
EOF
