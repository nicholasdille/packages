#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo sbstp/kubie \
    --match name \
    --asset kubie-linux-amd64 \
    --type binary \
    --name kubie

github_find_latest_release sbstp/kubie | \
    jq --raw-output '.tag_name' | \
    xargs -I{} curl --location --fail https://github.com/sbstp/kubie/raw/{}/completion/kubie.bash | \
    store_completion kubie
