#!/bin/bash

set -o errexit

clean() {
    docker rm regctl
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker run -i --name regctl golang bash -xe <<EOF
git clone https://github.com/regclient/regclient
cd regclient
go build -ldflags "-linkmode external -extldflags -static" -a -o regctl ./cmd/regctl/
cp /go/bin/regctl /
EOF
docker cp regctl:/regctl - | sudo tar -xvC ${TARGET}/bin/
