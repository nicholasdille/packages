#!/bin/bash

set -o errexit

sudo mkdir -p /opt/cni/bin
curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | \
    jq --raw-output '.assets[] | select(.name | startswith("cni-plugins-linux-amd64")) | select(.name | endswith(".tgz")) | .browser_download_url' | \
    xargs curl -Lf | \
    sudo tar -xzC /opt/cni/bin/
