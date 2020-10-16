#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

build_containerized golang <<EOF
go get -u github.com/cloudflare/cloudflare-go/cmd/flarectl
cp /go/bin/flarectl /
EOF
extract_file_from_container flarectl
