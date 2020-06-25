#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "kind-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/kind
sudo chmod +x ${TARGET}/bin/kind

# kind completion bash
