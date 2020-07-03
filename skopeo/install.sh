#!/bin/bash

set -o errexit

clean() {
    docker rm skopeo
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker run -i --name skopeo golang bash -xe <<EOF
git clone --depth 1 https://github.com/containers/skopeo
cd skopeo
make bin/skopeo DISABLE_CGO=1
cp bin/skopeo /
EOF
docker cp skopeo:/skopeo - | sudo tar -xvC ${TARGET}/bin/
