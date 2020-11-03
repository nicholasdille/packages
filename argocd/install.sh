#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo argoproj/argo-cd \
    --match name \
    --asset argocd-linux-amd64 \
    --type binary \
    --name argocd

argocd completion bash | \
    store_completion argocd
