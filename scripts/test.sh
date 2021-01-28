#!/bin/bash
set -o errexit

: "${CACHE_DIR:=${HOME}/.local/var/cache/pkgctl}"
mkdir -p "${CACHE_DIR}"

make packages.json

# shellcheck disable=SC1091
source /etc/lsb-release
if test "${DISTRIB_ID}" != "Ubuntu"; then
    echo "ERROR: Distribution ${DISTRIB_ID} is unsupported"
    exit 1
fi

unique_name=$(basename "$(mktemp --dry-run)")

docker ps \
        --filter name="test-build-${unique_name}" \
        --all \
        --quiet | \
    xargs -r \
        docker rm --force
docker run \
    --name "test-build-${unique_name}" \
    --detach \
    --env GITHUB_TOKEN \
    --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    --mount "type=bind,src=${PWD}/packages.json,dst=/root/.pkgctl/packages.json" \
    --mount "type=bind,src=${PWD}/pkgctl.sh,dst=/usr/local/bin/pkgctl.sh" \
    --mount "type=bind,src=${CACHE_DIR},dst=/root/.local/var/cache/pkgctl" \
    "nicholasdille/packages-runtime:${DISTRIB_ID,,}-${DISTRIB_CODENAME}"

function cleanup() {
    docker rm -f "test-build-${unique_name}"
}
trap cleanup EXIT

while test "$#" -gt 0; do
    PACKAGE=$1
    shift

    REQUIRES_DOCKER="$(
        jq \
            --raw-output \
            --arg package "${PACKAGE}" \
            '.packages[] | select(.name == $package) | .install.docker' \
            packages.json
    )"
    if test "${REQUIRES_DOCKER}" == "true"; then
        docker exec --env TARGET_BASE "test-build-${unique_name}" pkgctl.sh install docker
    fi

    docker exec --env TARGET_BASE "test-build-${unique_name}" pkgctl.sh install "${PACKAGE}"

done