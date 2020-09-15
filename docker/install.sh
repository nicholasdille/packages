#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/docker/docker-ce/releases/latest | \
    jq --raw-output '.name' | \
    xargs -I{} curl --location --fail https://download.docker.com/linux/static/stable/x86_64/docker-{}.tgz | \
    sudo tar -xzC ${TARGET}/bin/ --strip-components=1

sudo mkdir -p ${TARGET}/etc/bash_completion.d
curl --silent https://api.github.com/repos/docker/docker-ce/releases/latest | \
    jq --raw-output '.tag_name' | \
    xargs -I{} curl --location --fail https://raw.githubusercontent.com/docker/cli/{}/contrib/completion/bash/docker | \
    sudo tee ${TARGET}/etc/bash_completion.d/docker.sh >/dev/null
sudo ln -sf ${TARGET}/etc/bash_completion.d/docker.sh /etc/bash_completion.d/

: "${DOCKER_CONFIG:=${HOME}/.docker}"
if ! test -d "${DOCKER_CONFIG}"; then
    mkdir --parents ${DOCKER_CONFIG}
fi

if ! test -f "${DOCKER_CONFIG}/config.json"; then
    echo "{}" >${DOCKER_CONFIG}/config.json
fi

cp ${DOCKER_CONFIG}/config.json ${DOCKER_CONFIG}/config.json.bak
cat ${DOCKER_CONFIG}/config.json.bak | \
    jq '. + {"features":{"buildkit":true}}' \
    >${DOCKER_CONFIG}/config.json
