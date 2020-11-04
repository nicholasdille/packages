#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

github_find_latest_release kubernetes-sigs/krew | \
    github_resolve_assets | \
    github_select_asset_by_name krew.tar.gz | \
    github_get_asset_download_url | \
    download_file | \
    untar_file ./krew-linux_amd64
rename_file krew-linux_amd64 krew

krew update
if ! krew index list | grep --quiet kvaps; then
    krew index add kvaps https://github.com/kvaps/krew-index
fi

krew install \
    access-matrix \
    advise-psp \
    cert-manager \
    debug \
    doctor \
    exec-as \
    get-all \
    images \
    neat \
    net-forward \
    node-shell \
    rbac-lookup \
    rbac-view \
    resource-capacity \
    score \
    sniff \
    sort-manifests \
    status \
    sudo \
    tap \
    tmux-exec \
    tree \
    view-allocations \
    who-can \
    whoami \
    kvaps/use

kubectl use -completion | \
    store_completion kubectl-use
