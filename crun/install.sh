#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_install \
    --repo containers/crun \
    --match suffix \
    --asset -linux-amd64 \
    --type binary \
    --name crun

${SUDO} mkdir -p /etc/docker
if ! test -f /etc/docker/daemon.json; then
    echo "{}" | ${SUDO} tee /etc/docker/daemon.json >/dev/null
fi

${SUDO} mv /etc/docker/daemon.json /etc/docker/daemon.json.bak
jq --arg bin "${TARGET_BIN}" '. * {"runtimes": {"crun": {"path": ($bin + "/crun")}}}' /etc/docker/daemon.json.bak | \
    ${SUDO} tee /etc/docker/daemon.json >/dev/null
