#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/sysdiglabs/kube-psp-advisor/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("_linux_amd64.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    tar -xzC /tmp/ kubectl-advise-psp
sudo mv /tmp/kubectl-advise-psp ${TARGET}/bin/kube-advise-psp
