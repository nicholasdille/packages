#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo containers/podman \
    --match name \
    --asset podman-remote-static.tar.gz \
    --type tarball \
    --include podman-remote-static

rename_file podman-remote-static podman
