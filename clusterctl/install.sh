#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/kubernetes-sigs/cluster-api/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "clusterctl-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --silent --location --fail --output ${TARGET}/bin/clusterctl
sudo chmod +x ${TARGET}/bin/clusterctl
