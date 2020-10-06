#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --name argocd \
    --repo argoproj/argo-cd \
    --match name \
    --asset argocd-linux-amd64
    --type binary \

argocd completion bash | \
    store_completion argocd
