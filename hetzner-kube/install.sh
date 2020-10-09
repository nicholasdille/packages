#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo xetys/hetzner-kube \
    --match suffix \
    --asset -linux-amd64 \
    --type binary \
    --name hetzner-kube

hetzner-kube completion bash | \
    store_completion hetzner-kube
