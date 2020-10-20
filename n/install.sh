#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

TAG=$(
    github_find_latest_release tj/n | \
        jq --raw-output '.tag_name'
)

echo "https://github.com/tj/n/raw/${TAG}/bin/n" | \
    download_file | \
    store_file n | \
    make_executable

echo
echo "#############################################"
echo "### Now add the following to your ~/.bashrc:"
echo "###"
echo "export N_PREFIX=\${HOME}/.n"
echo "#############################################"
echo
