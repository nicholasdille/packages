#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
check_docker
unlock_sudo

TAG=$(
    github_find_latest_release cloudflare/cloudflare-go | \
        jq --raw-output '.tag_name'
)

build_containerized golang <<EOF
git clone https://github.com/cloudflare/cloudflare-go /go/src/github.com/cloudflare/cloudflare-go
cd /go/src/github.com/cloudflare/cloudflare-go
go mod download
go build -ldflags "-X main.version=${TAG}" github.com/cloudflare/cloudflare-go/cmd/flarectl
cp flarectl /
EOF
extract_file_from_container flarectl
