#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/moby/buildkit/releases | \
    jq 'map(select(.tag_name | startswith("v"))) | .[0]' | \
    jq --raw-output '.assets[] | select(.name | endswith(".linux-amd64.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}

curl --silent https://api.github.com/repos/moby/buildkit/releases | \
    jq --raw-output 'map(select(.tag_name | startswith("v"))) | .[0].tag_name' | \
    xargs -I{} sudo curl --location --fail --output ${TARGET}/bin/buildctl-daemonless.sh https://raw.githubusercontent.com/moby/buildkit/{}/examples/buildctl-daemonless/buildctl-daemonless.sh
sudo chmod +x ${TARGET}/bin/buildctl-daemonless.sh
