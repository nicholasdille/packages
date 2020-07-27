#!/bin/bash

set -o errexit

clean() {
    docker rm json-patch
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker run -i --name json-patch golang bash -xe <<EOF
go get -u github.com/evanphx/json-patch/cmd/json-patch
cp /go/bin/json-patch /
EOF
docker cp json-patch:/json-patch - | sudo tar -xvC ${TARGET}/bin/
