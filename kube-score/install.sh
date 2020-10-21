#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo zegl/kube-score \
    --match suffix \
    --asset _linux_amd64.tar.gz \
    --type binary \
    --name kube-score

curl --silent https://api.github.com/repos/zegl/kube-score/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("_linux_amd64.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    ${SUDO} tar -xzC "${TARGET}/bin"
