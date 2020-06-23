#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

if [[ "$(curl --silent https://api.github.com/repos/rancher/k3d/releases/latest | jq --raw-output '.tag_name')" =~ /^v3./ ]]; then
    echo "ERROR: Version 3 was released. Please correct install.sh"
    exit 1
fi

curl --silent https://api.github.com/repos/rancher/k3d/releases | \
    jq -r '.[] | select(.tag_name | startswith("v3.0.0-rc.")) | .tag_name' | \
    sort --version-sort --reverse | head -n 1 | \
    xargs -I{} curl --silent https://api.github.com/repos/rancher/k3d/releases/tags/{} | \
    jq --raw-output '.assets[] | select(.name == "k3d-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/k3d
sudo chmod +x ${TARGET}/bin/k3d

sudo mkdir -p ${TARGET}/etc/bash_completion.d
k3d completion bash | sudo tee ${TARGET}/etc/bash_completion.d/k3d.sh >/dev/null
sudo ln -sf ${TARGET}/etc/bash_completion.d/k3d.sh /etc/bash_completion.d/
