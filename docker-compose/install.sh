#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/docker/compose/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "docker-compose-Linux-x86_64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/docker-compose
sudo chmod +x ${TARGET}/bin/docker-compose

# https://github.com/docker/compose/blob/master/contrib/completion/bash/docker-compose

sudo mkdir -p ${TARGET}/etc/bash_completion.d
curl --silent https://api.github.com/repos/docker/compose/releases/latest | \
    jq --raw-output '.tag_name' | \
    xargs -I{} curl --location --fail https://github.com/docker/compose/blob/{}/contrib/completion/bash/docker-compose | \
    sudo tee ${TARGET}/etc/bash_completion.d/docker-compose.sh >/dev/null
sudo ln -s ${TARGET}/etc/bash_completion.d/docker-compose.sh /etc/bash_completion.d/
