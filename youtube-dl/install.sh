#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_find_latest_release ytdl-org/youtube-dl | \
    jq --raw-output '.tag_name' | \
    xargs -I{} echo "https://github.com/ytdl-org/youtube-dl/releases/download/{}/youtube-dl" | \
    download_file | \
    store_file youtube-dl | \
    make_executable
