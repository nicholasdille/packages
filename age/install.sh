#!/bin/bash

set -o errexit

clean() {
    docker rm age
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker run -i --name age golang bash -xe <<EOF
git clone https://filippo.io/age
cd age
go build -o . filippo.io/age/cmd/...
cp age age-keygen /
EOF
docker cp age:/age - | sudo tar -xvC ${TARGET}/bin/
docker cp age:/age-keygen - | sudo tar -xvC ${TARGET}/bin/
