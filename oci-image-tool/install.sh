#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

build_containerized golang <<EOF
go get github.com/cpuguy83/go-md2man
go get -d github.com/opencontainers/image-tools/cmd/oci-image-tool
cd /go/src/github.com/opencontainers/image-tools/
make all
cp oci-image-tool /
EOF
extract_file_from_container oci-image-tool

for MAN in oci-image-tool oci-image-tool-create oci-image-tool-unpack oci-image-tool-validate; do
    # shellcheck disable=SC2154
    docker cp "${container_name}:/go/src/github.com/opencontainers/image-tools/${MAN}.1" - | \
        tar -x --to-stdout | \
        sudo tee "${TARGET_BASE}/share/man/man1/${MAN}.1" >/dev/null
done
