#!/bin/bash

set -o errexit

clean() {
    docker rm docker-ls
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker run -i --name docker-ls golang bash <<EOF
go get -d github.com/mayflower/docker-ls/cli/...
go generate github.com/mayflower/docker-ls/lib/...
go install github.com/mayflower/docker-ls/cli/...
cp /go/bin/docker-ls /go/bin/docker-rm /
EOF
docker cp docker-ls:/docker-ls - | sudo tar -xvC ${TARGET}/bin/
docker cp docker-ls:/docker-rm - | sudo tar -xvC ${TARGET}/bin/

# docker-ls autocomplete bash
# docker-rm autocomplete bash
