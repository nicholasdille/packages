#!/bin/bash

clean() {
    docker rm kube-ps1
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker run -i --name kube-ps1 alpine sh -xe <<EOF
apk add --update-cache --no-cache git curl jq
git clone https://github.com/jonmosco/kube-ps1
cd kube-ps1
curl --silent https://api.github.com/repos/jonmosco/kube-ps1/releases/latest | jq --raw-output '.tag_name' | xargs git checkout
cp kube-ps1.sh /
EOF
docker cp kube-ps1:/kube-ps1.sh - | sudo tar -xvC ${TARGET}/bin/

# TODO: source in ~/.bashrc
