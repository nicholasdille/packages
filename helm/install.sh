#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent --location -o /dev/null -w %{url_effective} https://github.com/helm/helm/releases/latest | \
    grep -oE "[^/]+$" | \
    xargs -I{} curl --location --fail "https://get.helm.sh/helm-{}-linux-amd64.tar.gz" | \
    sudo tar -xz --strip-components=1 -C ${TARGET}/bin/ linux-amd64/helm

sudo mkdir -p ${TARGET}/etc/bash_completion.d
helm completion bash | sudo tee ${TARGET}/etc/bash_completion.d/helm.sh >/dev/null
sudo ln -sf ${TARGET}/etc/bash_completion.d/helm.sh /etc/bash_completion.d/

# https://github.com/databus23/helm-diff
helm plugin install https://github.com/databus23/helm-diff
