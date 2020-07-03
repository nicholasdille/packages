#!/bin/bash

set -o errexit

clean() {
    docker rm yamlpatch
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker run -i --name yamlpatch golang bash -xe <<EOF
go get github.com/krishicks/yaml-patch/cmd/yaml-patch
cp /go/bin/yaml-patch /
EOF
docker cp yamlpatch:/yaml-patch - | sudo tar -xvC ${TARGET}/bin/
