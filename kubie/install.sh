#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/sbstp/kubie/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "kubie-linux-amd64") | .browser_download_url' | \
    xargs sudo curl --location --fail --output ${TARGET}/bin/kubie
sudo chmod +x ${TARGET}/bin/kubie

curl --silent https://api.github.com/repos/sbstp/kubie/releases/latest | \
    jq --raw-output '.tag_name' | \
    xargs -I{} sudo curl --location --fail --output ${TARGET}/etc/bash_completion.d/kubie.sh https://github.com/sbstp/kubie/raw/{}/completion/kubie.bash
