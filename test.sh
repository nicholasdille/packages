#!/bin/bash
set -o errexit

PACKAGE=$1
if test -z "${PACKAGE}"; then
    echo "ERROR: Package name not specified"
    exit 1
fi

make packages.json

DOCKER_BUILDKIT=1 docker build --target ubuntu --tag test-package:ubuntu .

docker ps --filter name="test-${PACKAGE}" --all --quiet | xargs -r docker rm -f
docker run -d --name "test-${PACKAGE}" --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock test-package:ubuntu

function cleanup() {
    docker rm -f "test-${PACKAGE}"
}
trap cleanup EXIT

docker exec "test-${PACKAGE}" mkdir /root/.pkgctl
docker cp pkgctl.sh "test-${PACKAGE}:/usr/local/bin/pkgctl"
docker cp packages.json "test-${PACKAGE}:/root/.pkgctl/packages.json"

REQUIRES_DOCKER="$(
    jq --raw-output --arg package "${PACKAGE}" '.packages[] | select(.name == $package) | .install.docker' packages.json
)"
if test "${REQUIRES_DOCKER}" == "true"; then
    docker exec "test-${PACKAGE}" pkgctl install docker
fi

docker exec "test-${PACKAGE}" pkgctl install ${PACKAGE}
