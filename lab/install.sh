#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo zaquestion/lab \
    --match suffix \
    --asset _linux_amd64.tar.gz \
    --type tarball \
    --include lab

lab completion bash | \
    store_completion lab
