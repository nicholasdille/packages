#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl -s https://api.github.com/repos/github/hub/releases/latest | \
    jq --raw-output '.assets[] | select(.name  | startswith("hub-linux-amd64-")) | .browser_download_url' | \
    xargs curl -Lf | \
    sudo tar -xzC ${TARGET} --wildcards --strip-components=1 */bin/hub
mkdir -p ${TARGET}/etc/bash_completion.d || sudo mkdir -p ${TARGET}/etc/bash_completion.d
curl -s https://api.github.com/repos/github/hub/releases/latest | \
    jq --raw-output '.assets[] | select(.name  | startswith("hub-linux-amd64-")) | .browser_download_url' | \
    xargs curl -Lf | \
    sudo tar -xzC ${TARGET}/etc/bash_completion.d/ --wildcards --strip-components=2 */etc/hub.bash_completion.sh

curl -s https://api.github.com/repos/cli/cli/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("_linux_amd64.tar.gz")) | .browser_download_url' | \
    xargs curl -Lf | \
    sudo tar -xzC ${TARGET}/bin/ --wildcards --strip-components=2 */bin/gh
