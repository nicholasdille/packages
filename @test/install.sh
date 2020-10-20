#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
#source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)
source .scripts/source.sh

unlock_sudo

github_find_latest_release sharkdp/bat
github_resolve_assets
github_select_asset_by_prefix bat-
github_select_asset_by_suffix -x86_64-unknown-linux-gnu.tar.gz
github_get_asset_download_url
github_download_file

untar_file "bat-${GITHUB_RELEASE_TAG}-x86_64-unknown-linux-gnu.tar.gz" "" --wildcards --strip-components=1 "*/bat"
untar_file "bat-${GITHUB_RELEASE_TAG}-x86_64-unknown-linux-gnu.tar.gz" "${TARGET_BASE}/man/man1" --wildcards --strip-components=1 "*/bat.1"
