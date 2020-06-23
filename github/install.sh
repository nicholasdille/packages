#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/github/hub/releases/latest | \
    jq --raw-output '.assets[] | select(.name  | startswith("hub-linux-amd64-")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET} --wildcards --strip-components=1 */bin/hub

mkdir -p ${TARGET}/etc/bash_completion.d || sudo mkdir -p ${TARGET}/etc/bash_completion.d
curl --silent https://api.github.com/repos/github/hub/releases/latest | \
    jq --raw-output '.assets[] | select(.name  | startswith("hub-linux-amd64-")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/etc/bash_completion.d/ --wildcards --strip-components=2 */etc/hub.bash_completion.sh

curl --silent https://api.github.com/repos/cli/cli/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("_linux_amd64.tar.gz")) | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ --wildcards --strip-components=2 */bin/gh

gh completion | sudo tee ${TARGET}/etc/bash_completion.d/gh.sh >/dev/null
sudo ln -sf ${TARGET}/etc/bash_completion.d/gh.sh /etc/bash_completion.d/
