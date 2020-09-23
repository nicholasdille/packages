#!/bin/bash

set -o errexit

clean() {
    docker rm tig
}

trap clean EXIT

: "${TARGET:=/usr/local}"

docker create -i --name tig ubuntu bash -xe

curl --silent https://api.github.com/repos/jonas/tig/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith(".tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    gunzip | \
    docker cp - tig:/

docker start -i tig <<EOF
apt-get update
apt-get -y install --no-install-recommends curl jq gcc ncurses-dev make
cd tig-*
./configure
make prefix=/usr/local
make install prefix=/usr/local
EOF
docker cp tig:/usr/local/bin/tig - | sudo tar -xvC ${TARGET}/bin/
