#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo kubernetes-sigs/kind \
    --match name \
    --asset kind-linux-amd64 \
    --type binary \
    --name kind

kind completion bash | \
    store_completion kind
