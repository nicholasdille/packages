#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

sudo apt-get update
sudo apt-get -y install bpfcc-tools

github_install \
    --repo aquasecurity/tracee \
    --match name \
    --asset tracee.tar.gz \
    --type tarball \
    --include tracee
