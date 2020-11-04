#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo hetznercloud/cli \
    --match name \
    --asset hcloud-linux-amd64.tar.gz \
    --type tarball \
    --include hcloud

hcloud completion bash | \
    store_completion hcloud
