#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://api.github.com/repos/kubernetes-sigs/krew/releases/latest | \
    jq --raw-output '.assets[] | select(.name == "krew.tar.gz") | .browser_download_url' | \
    xargs curl --location --fail | \
    ${SUDO} tar -xzC ${TARGET}/bin/ ./krew-linux_amd64
${SUDO} mv ${TARGET}/bin/krew-linux_amd64 ${TARGET}/bin/krew

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
    ${SUDO} tee ${TARGET}/etc/bash_completion.d/kubectl-use.sh >/dev/null
${SUDO} ln -sf ${TARGET}/etc/bash_completion.d/kubectl-use.sh /etc/bash_completion.d/
