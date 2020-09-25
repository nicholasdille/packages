#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/cyberark/kubeletctl/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "kubeletctl_linux_amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/kubeletctl
sudo chmod +x ${TARGET}/bin/kubeletctl
