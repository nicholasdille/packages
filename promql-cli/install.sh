#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
check_docker
unlock_sudo

TAG=$(
    github_find_latest_release nalbury/promql-cli | \
        jq --raw-output '.tag_name'
)

build_containerized golang <<EOF
git clone https://github.com/nalbury/promql-cli
cd promql-cli
git checkout "${TAG}"
go mod download
go build -o promql .
cp promql /
EOF
extract_file_from_container promql
