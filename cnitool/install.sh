#!/bin/bash

set -o errexit

clean() {
    docker rm cnitool
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker run -i --name cnitool golang bash <<EOF
go get github.com/containernetworking/cni
go install github.com/containernetworking/cni/cnitool
cp /go/bin/cnitool /
EOF
docker cp cnitool:/cnitool - | sudo tar -xvC ${TARGET}/bin/
