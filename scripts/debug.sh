#!/bin/bash
set -o errexit

: "${CACHE_DIR:=${HOME}/.local/var/cache/pkgctl}"
mkdir -p "${CACHE_DIR}"

make packages.json

if test "$#" -eq 2; then
    ID=$1
    VERSION_ID=$2
fi
if test -z "${ID}" || test -z "${VERSION_ID}"; then
    # shellcheck disable=SC1091
    source /etc/os-release
fi
if test -z "${ID}" || test -z "${VERSION_ID}"; then
    echo "ERROR: Unable to determine distribution and/or version."
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
    "nicholasdille/packages-runtime:${ID,,}-${VERSION_ID}"

function cleanup() {
    docker rm -f "test-build-${unique_name}"
}
trap cleanup EXIT

docker exec \
    --interactive \
    --tty \
    --env TARGET_BASE \
    "test-build-${unique_name}" bash
