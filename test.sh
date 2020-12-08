#!/bin/bash

PACKAGE=$1
if test -z "${PACKAGE}"; then
    echo "ERROR: Package name not specified"
    exit 1
fi

make packages.json

DOCKER_BUILDKIT=1 docker build --target ubuntu --tag test-package:ubuntu .

docker ps --filter name="test-${PACKAGE}" --all --quiet | xargs -r docker rm -f
docker run -d --name "test-${PACKAGE}" --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock test-package:ubuntu
docker exec "test-${PACKAGE}" mkdir /root/.pkgctl
docker cp pkgctl.sh "test-${PACKAGE}:/usr/local/bin/pkgctl"
docker cp packages.json "test-${PACKAGE}:/root/.pkgctl/packages.json"
docker exec "test-${PACKAGE}" pkgctl install docker
docker exec "test-${PACKAGE}" pkgctl install ${PACKAGE}
docker rm -f "test-${PACKAGE}"