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
git clone https://github.com/FiloSottile/age
cd age
git checkout ${TAG}
go build -o . filippo.io/age/cmd/...
cp age age-keygen /
EOF
extract_file_from_container age age-keygen
