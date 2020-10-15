#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo weaveworks/eksctl \
    --match name \
    --asset eksctl_Linux_amd64.tar.gz \
    --type tarball \
    --include eksctl
