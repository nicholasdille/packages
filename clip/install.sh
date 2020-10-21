#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"
: "${DOCKER_CLI_DIR:=${TARGET}/lib/docker/cli-plugins}"

REQUIRED_DOCKER_VERSION=19.03
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

${SUDO} mkdir --parents ${DOCKER_CLI_DIR}

${SUDO} curl --location --fail --output ${DOCKER_CLI_DIR}/docker-clip https://github.com/lukaszlach/clip/raw/master/docker-clip
${SUDO} chmod +x ${DOCKER_CLI_DIR}/docker-clip
