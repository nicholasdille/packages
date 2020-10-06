#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --name docker-compose \
    --repo docker/compose \
    --match name \
    --asset docker-compose-Linux-x86_64 \
    --type binary

sudo mkdir -p ${TARGET}/etc/bash_completion.d
curl --silent https://api.github.com/repos/docker/compose/releases/latest | \
    jq --raw-output '.tag_name' | \
    xargs -I{} curl --location --fail https://github.com/docker/compose/raw/{}/contrib/completion/bash/docker-compose | \
    sudo tee ${TARGET}/etc/bash_completion.d/docker-compose.sh >/dev/null
sudo ln -sf ${TARGET}/etc/bash_completion.d/docker-compose.sh /etc/bash_completion.d/
