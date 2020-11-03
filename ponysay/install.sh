#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

TAG=$(
    github_find_latest_release erkin/ponysay | \
        jq --raw-output '.tag_name'
)

build_containerized python <<EOF
apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get -y install texinfo
git clone https://github.com/erkin/ponysay
cd ponysay
git checkout ${TAG}
./setup.py --freedom=partial install
EOF
#extract_file_from_container ponysay
