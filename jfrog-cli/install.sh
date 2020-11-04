#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

TAG=$(
    github_find_latest_release jfrog/jfrog-cli | \
        jq --raw-output '.tag_name'
)

echo "https://api.bintray.com/content/jfrog/jfrog-cli-go/${TAG#v}/jfrog-cli-linux-amd64/jfrog?bt_package=jfrog-cli-linux-amd64" | \
    download_file | \
    store_file jfrog | \
    make_executable
