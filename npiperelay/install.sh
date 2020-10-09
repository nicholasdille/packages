#!/bin/bash

set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo NZSmartie/npiperelay \
    --match name \
    --asset npiperelay.exe \
    --type binary \
    --name npiperelay.exe
