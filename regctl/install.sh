#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

build_containerized golang <<EOF
git clone https://github.com/regclient/regclient
cd regclient
go build -ldflags "-linkmode external -extldflags -static" -a -o regctl ./cmd/regctl/
cp /go/bin/regctl /
EOF
extract_file_from_container regctl
