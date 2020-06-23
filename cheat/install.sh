#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/cheat/cheat/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "cheat-linux-amd64.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    gunzip | \
    sudo tee ${TARGET}/bin/cheat >/dev/null
sudo chmod +x ${TARGET}/bin/cheat

mkdir -p ~/.config/cheat/cheatsheets/personal
cheat --init > ~/.config/cheat/conf.yml
git clone https://github.com/cheat/cheatsheets ~/.config/cheat/cheatsheets/community
