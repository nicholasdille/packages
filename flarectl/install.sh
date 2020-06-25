#!/bin/bash

clean() {
    docker rm flarectl
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker run -i --name flarectl golang bash <<EOF
go get -u github.com/cloudflare/cloudflare-go/cmd/flarectl
cp /go/bin/flarectl /
EOF
docker cp flarectl:/flarectl - | sudo tar -xvC ${TARGET}/bin/
