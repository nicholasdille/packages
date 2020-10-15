#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

echo "https://storage.googleapis.com/gvisor/releases/release/latest/runsc" | \
    download_file | \
    store_file runsc | \
    make_executable

sudo runsc install
