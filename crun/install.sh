#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo containers/crun \
    --match suffix \
    --asset -linux-amd64 \
    --type binary \
    --name crun

sudo mkdir -p /etc/docker
if ! test -f /etc/docker/daemon.json; then
    echo "{}" | sudo tee /etc/docker/daemon.json >/dev/null
fi

sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.bak
cat /etc/docker/daemon.json.bak | \
    jq --arg bin "${TARGET_BIN}" '. * {"runtimes": {"crun": {"path": ($bin + "/crun")}}}' | \
    sudo tee /etc/docker/daemon.json >/dev/null
