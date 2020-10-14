#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release kata-containers/runtime | \
    github_resolve_assets | \
    github_select_asset_by_suffix -x86_64.tar.xz | \
    github_get_asset_download_url | \
    download_file | \
    sudo tar -xJC ${TARGET_BASE} --strip-components=3

sudo mkdir -p /etc/docker
if ! test -f /etc/docker/daemon.json; then
    echo "{}" | sudo tee /etc/docker/daemon.json >/dev/null
fi

sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.bak
cat /etc/docker/daemon.json.bak | \
    jq --arg bin "${TARGET_BIN}" '. * {"runtimes": {"kata-runtime": {"path": ($bin + "/kata-runtime")}}}' | \
    sudo tee /etc/docker/daemon.json >/dev/null
