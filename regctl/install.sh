#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
check_docker
unlock_sudo

TAG=$(
    github_find_latest_release regclient/regclient | \
        jq --raw-output '.tag_name'
)

build_containerized golang <<EOF
git clone https://github.com/regclient/regclient
cd regclient
git checkout ${TAG}
go build -ldflags "-linkmode external -extldflags -static" -a -o regctl ./cmd/regctl/
cp regctl /
EOF
extract_file_from_container regctl
