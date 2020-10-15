#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release sahsanu/lectl | \
    jq --raw-output '.tag_name' | \
    xargs -I{} curl --location --fail https://raw.githubusercontent.com/sahsanu/lectl/{}/lectl | \
    store_file lectl
