#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

TAG=$(
    github_find_latest_release containers/conmon | \
        jq --raw-output '.tag_name'
)

curl --silent https://pkg.dille.io/conmon/Dockerfile | \
    docker build --tag conmon -

build_containerized conmon <<EOF
cd /tmp
git clone https://github.com/containers/conmon
cd conmon
git checkout "${TAG}"
PREFIX=/usr/local make all
cp bin/conmon /
EOF
extract_file_from_container conmon
