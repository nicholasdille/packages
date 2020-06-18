#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl -Ls -o /dev/null -w %{url_effective} https://github.com/helm/helm/releases/latest | \
    grep -oE "[^/]+$" | \
    xargs -I{} curl -Lf "https://get.helm.sh/helm-{}-linux-amd64.tar.gz" | \
    sudo tar -xz --strip-components=1 -C ${TARGET}/bin/ linux-amd64/helm
