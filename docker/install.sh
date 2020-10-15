#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release docker/docker-ce | \
    jq --raw-output '.name' | \
    xargs -I{} curl --location --fail https://download.docker.com/linux/static/stable/x86_64/docker-{}.tgz | \
    untar_file --strip-components=1

github_find_latest_release docker/docker-ce | \
    jq --raw-output '.tag_name' | \
    xargs -I{} curl --location --fail https://raw.githubusercontent.com/docker/cli/{}/contrib/completion/bash/docker | \
    store_completion docker

: "${DOCKER_CONFIG:=${HOME}/.docker}"
if ! test -d "${DOCKER_CONFIG}"; then
    mkdir --parents "${DOCKER_CONFIG}"
fi

if ! test -f "${DOCKER_CONFIG}/config.json"; then
    echo "{}" >"${DOCKER_CONFIG}/config.json"
fi

cp "${DOCKER_CONFIG}/config.json" "${DOCKER_CONFIG}/config.json.bak"
jq '. + {"features":{"buildkit":true}}' "${DOCKER_CONFIG}/config.json.bak" >"${DOCKER_CONFIG}/config.json"
