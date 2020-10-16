#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

TAG=$(
    github_get_tags filosottile/age | \
        github_select_latest_tag
)

build_containerized golang <<EOF
go get github.com/krishicks/yaml-patch/cmd/yaml-patch
cp /go/bin/yaml-patch /
EOF
extract_file_from_container yaml-patch
