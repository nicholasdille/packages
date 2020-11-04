#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
check_docker
unlock_sudo

build_containerized golang <<EOF
go get github.com/cpuguy83/go-md2man
go get -d github.com/opencontainers/runtime-tools/cmd/oci-runtime-tool
cd /go/src/github.com/opencontainers/runtime-tools/
make all man
cp oci-runtime-tool /
EOF
extract_file_from_container oci-runtime-tool

for MAN in oci-runtime-tool oci-runtime-tool-generate oci-runtime-tool-validate; do
    # shellcheck disable=SC2154
    docker cp "${container_name}:/go/src/github.com/opencontainers/runtime-tools/${MAN}.1" - | \
        tar -x --to-stdout | \
        sudo tee "${TARGET_BASE}/share/man/man1/${MAN}.1" >/dev/null
done
