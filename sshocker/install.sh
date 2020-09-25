#!/bin/bash

set -o errexit

clean() {
    docker rm sshocker
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker run -i --name sshocker golang bash -xe <<EOF
go get github.com/AkihiroSuda/sshocker/cmd/sshocker
cp /go/bin/sshocker /
EOF
docker cp sshocker:/sshocker - | sudo tar -xvC ${TARGET}/bin/
