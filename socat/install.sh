#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

export DOCKER_BUILDKIT=1
curl --silent https://pkg.dille.io/socat/Dockerfile | \
    docker build --tag socat -

build_containerized socat <<"EOF"
cd /tmp
git clone https://repo.or.cz/socat.git
cd socat
TAG=$(git tag | grep -E "^tag-1\." | sort -V -r | head -n 1)
git checkout "${TAG}"
autoconf
./configure
make
cp socat /
cp doc/socat.1 /
EOF
extract_file_from_container socat

# shellcheck disable=SC2154
docker cp "${container_name}:/tmp/socat/doc/socat.1" - | \
    sudo tee "${TARGET_BASE}/share/man/man1/socat.1" >/dev/null