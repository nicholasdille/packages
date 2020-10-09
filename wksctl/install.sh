#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo weaveworks/wksctl \
    --match suffix \
    --asset -linux-x86_64.tar.gz \
    --type tarball \
    --include wksctl