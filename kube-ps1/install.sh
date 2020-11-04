#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
check_docker
unlock_sudo

build_containerized alpine sh -xe <<EOF
apk add --update-cache --no-cache git curl jq
git clone https://github.com/jonmosco/kube-ps1
cd kube-ps1
curl --silent https://api.github.com/repos/jonmosco/kube-ps1/releases/latest | jq --raw-output '.tag_name' | xargs git checkout
cp kube-ps1.sh /
EOF
extract_file_from_container kube-ps1.sh

curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file kube-ps1 profile.d.kube-ps1.sh | \
    store_file kube-ps1.sh /etc/profile.d
