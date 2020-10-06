#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --name clusterctl \
    --repo kubernetes-sigs/cluster-api \
    --match name \
    --asset clusterctl-linux-amd64 \
    --type binary

clusterctl completion bash | \
    store_completion clusterctl
