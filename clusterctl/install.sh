#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --name clusterctl \
    --repo kubernetes-sigs/cluster-api \
    --match name \
    --asset clusterctl-linux-amd64 \
    --type binary

clusterctl completion bash | \
    store_completion clusterctl
