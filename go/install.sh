#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

TAG=$(
    github_get_tags golang/go | \
        jq 'map(select(.ref | startswith("refs/tags/go")))' | \
        github_select_latest_tag
)

echo "https://dl.google.com/go/go${TAG#go}.linux-amd64.tar.gz" | \
    download_file | \
    sudo tar -xzC "${TARGET_BASE}"
sudo mv "${TARGET_BASE}/go" "${TARGET_BASE}/go${TAG#go}"

sudo update-alternatives --install "${TARGET_BIN}/go" "go" "${TARGET_BASE}/go${TAG#go}/bin/go" 1 \
sudo update-alternatives --set "go" "${TARGET_BASE}/go${TAG#go}/bin/go" \
sudo update-alternatives --install "${TARGET_BIN}/godoc" "godoc" "${TARGET_BASE}/go${TAG#go}/bin/godoc" 1 \
sudo update-alternatives --set "godoc" "${TARGET_BASE}/go${TAG#go}/bin/godoc" \
sudo update-alternatives --install "${TARGET_BIN}/gofmt" "gofmt" "${TARGET_BASE}/go${TAG#go}/bin/gofmt" 1 \
sudo update-alternatives --set "gofmt" "${TARGET_BASE}/go${TAG#go}/bin/gofmt"
