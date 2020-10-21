#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

curl --silent --location -o /dev/null -w "%{url_effective}" https://github.com/helm/helm/releases/latest | \
    grep -oE "[^/]+$" | \
    xargs -I{} curl --location --fail "https://get.helm.sh/helm-{}-linux-amd64.tar.gz" | \
    ${SUDO} tar -xz --strip-components=1 -C "${TARGET_BIN}" linux-amd64/helm

helm completion bash | \
    store_completion helm

# https://github.com/databus23/helm-diff
helm plugin install https://github.com/databus23/helm-diff
