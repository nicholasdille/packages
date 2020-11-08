#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

TAG=$(
    github_find_latest_release hashicorp/terraform | \
    jq --raw-output '.tag_name'
)

echo "https://releases.hashicorp.com/terraform/${TAG#v}/terraform_${TAG#v}_linux_amd64.zip" | \
    download_file | \
    store_file "terraform.zip" "${temporary_directory}"
unzip_file "${temporary_directory}/terraform.zip"
${SUDO} mv terraform "${TARGET_BIN}"
