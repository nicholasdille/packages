#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo hetznercloud/cli \
    --match name \
    --asset hcloud-linux-amd64.tar.gz \
    --type tarball \
    --include hcloud

hcloud completion bash | \
    store_completion hcloud
