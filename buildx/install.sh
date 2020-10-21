#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

: "${DOCKER_CLI_DIR:=${TARGET}/lib/docker/cli-plugins}"
: "${DOCKER_CONFIG:=${HOME}/.docker}"

REQUIRED_DOCKER_VERSION=18.09
# Get smaller version of required and current version
DOCKER_VERSION=$(\
    (\
        docker version --format '{{.Client.Version}}'; \
        echo "${REQUIRED_DOCKER_VERSION}"; \
    ) | \
    sort --version-sort | \
    head -n 1; \
)
# if smaller version if required version
if test "${DOCKER_VERSION}" != "${REQUIRED_DOCKER_VERSION}"; then
    echo "Error: Please install Docker >=${REQUIRED_DOCKER_VERSION}."
    exit 1
fi

${SUDO} mkdir --parents "${DOCKER_CLI_DIR}"

github_find_latest_release docker/buildx | \
    github_resolve_assets | \
    github_select_asset_by_suffix .linux-amd64 | \
    github_get_asset_download_url | \
    download_file | \
    store_file docker-buildx "${DOCKER_CLI_DIR}" | \
    make_executable

if ! test -f "${DOCKER_CONFIG}/config.json"; then
    echo "{}" >"${DOCKER_CONFIG}/config.json"
fi

cp "${DOCKER_CONFIG}/config.json" "${DOCKER_CONFIG}/config.json.bak"
jq '. + {"experimental": "enabled"}' "${DOCKER_CONFIG}/config.json.bak" >"${DOCKER_CONFIG}/config.json"
