#!/bin/bash
set -o errexit

make packages.json

# shellcheck disable=SC1091
source /etc/lsb-release
if test "${DISTRIB_ID}" != "Ubuntu"; then
    echo "ERROR: Distribution ${DISTRIB_ID} is unsupported"
    exit 1
fi
DOCKER_BUILDKIT=1 docker build --target "${DISTRIB_ID,,}-${DISTRIB_CODENAME}" --tag test-package:ubuntu .

docker ps --filter name="test-build" --all --quiet | xargs -r docker rm -f
docker run -d --name "test-build" --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock test-package:ubuntu

function cleanup() {
    docker rm -f "test-build"
}
trap cleanup EXIT

docker exec "test-build" mkdir /root/.pkgctl
docker cp pkgctl.sh "test-build:/usr/local/bin/pkgctl"
docker cp packages.json "test-build:/root/.pkgctl/packages.json"

while test "$#" -gt 0; do
    PACKAGE=$1
    shift

    REQUIRES_DOCKER="$(
        jq --raw-output --arg package "${PACKAGE}" '.packages[] | select(.name == $package) | .install.docker' packages.json
    )"
    if test "${REQUIRES_DOCKER}" == "true"; then
        docker exec "test-build" pkgctl install docker
    fi

    docker exec "test-build" pkgctl install "${PACKAGE}"

done