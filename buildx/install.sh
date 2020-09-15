#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"
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

sudo mkdir --parents ${DOCKER_CLI_DIR}

curl --silent https://api.github.com/repos/docker/buildx/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith(".linux-amd64")) | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${DOCKER_CLI_DIR}/docker-buildx
sudo chmod +x ${DOCKER_CLI_DIR}/docker-buildx

if ! test -f "${DOCKER_CONFIG}/config.json"; then
    echo "{}" >${DOCKER_CONFIG}/config.json
fi

cp ${DOCKER_CONFIG}/config.json ${DOCKER_CONFIG}/config.json.bak
cat ${DOCKER_CONFIG}/config.json.bak | \
    jq '. + {"experimental": "enabled"}' \
    >${DOCKER_CONFIG}/config.json
