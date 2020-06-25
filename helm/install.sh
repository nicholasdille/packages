#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent --location -o /dev/null -w %{url_effective} https://github.com/helm/helm/releases/latest | \
    grep -oE "[^/]+$" | \
    xargs -I{} curl --location --fail "https://get.helm.sh/helm-{}-linux-amd64.tar.gz" | \
    sudo tar -xz --strip-components=1 -C ${TARGET}/bin/ linux-amd64/helm

# helm completion bash
