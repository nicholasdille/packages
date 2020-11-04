#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
check_docker
unlock_sudo

build_containerized golang <<EOF
go get -d github.com/mayflower/docker-ls/cli/...
go generate github.com/mayflower/docker-ls/lib/...
go install github.com/mayflower/docker-ls/cli/...
cp /go/bin/docker-ls /go/bin/docker-rm /
EOF
extract_file_from_container docker-ls docker-rm

docker-ls autocomplete bash | \
    store_completion docker-ls

docker-rm autocomplete bash | \
    store_completion docker-rm
