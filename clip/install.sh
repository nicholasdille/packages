#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

: "${DOCKER_CLI_DIR:=${TARGET_BASE}/lib/docker/cli-plugins}"

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

unlock_sudo

${SUDO} mkdir --parents ${DOCKER_CLI_DIR}

echo "https://github.com/lukaszlach/clip/raw/master/docker-clip" | \
    download_file | \
    store_file docker-clip "${DOCKER_CLI_DIR}" |
    make_executable
