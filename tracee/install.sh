#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

sudo apt-get update
sudo apt-get -y install bpfcc-tools
curl --silent https://api.github.com/repos/aquasecurity/tracee/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "tracee.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    sudo tar -xzC ${TARGET}/bin/ tracee
