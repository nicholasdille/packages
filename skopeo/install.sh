#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
check_docker
unlock_sudo

TAG=$(
    github_find_latest_release containers/skopeo | \
        jq --raw-output '.tag_name'
)

build_containerized golang <<EOF
git clone https://github.com/containers/skopeo
cd skopeo
git checkout ${TAG}
make bin/skopeo DISABLE_CGO=1
cp bin/skopeo /
EOF
extract_file_from_container skopeo
