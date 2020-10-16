#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

build_containerized golang <<EOF
git clone --depth 1 https://github.com/containers/skopeo
cd skopeo
make bin/skopeo DISABLE_CGO=1
cp bin/skopeo /
EOF
extract_file_from_container skopeo
