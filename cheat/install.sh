#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo cheat/cheat \
    --match name \
    --asset cheat-linux-amd64.gz \
    --type gunzip \
    --name cheat

mkdir -p ~/.config/cheat/cheatsheets/personal
cheat --init > ~/.config/cheat/conf.yml
git clone https://github.com/cheat/cheatsheets ~/.config/cheat/cheatsheets/community
