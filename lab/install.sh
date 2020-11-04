#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo zaquestion/lab \
    --match suffix \
    --asset _linux_amd64.tar.gz \
    --type tarball \
    --include lab

lab completion bash | \
    store_completion lab
