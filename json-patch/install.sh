#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

build_containerized golang <<EOF
go get -u github.com/evanphx/json-patch/cmd/json-patch
cp /go/bin/json-patch /
EOF
extract_file_from_container json-patch
