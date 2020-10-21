#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"
ROOT=$(dirname "$(readlink -f "$0")")

curl --silent https://api.github.com/repos/justjanne/powerline-go/releases/latest | \
    jq --raw-output '.assets[] | select(.name | endswith("-linux-amd64")) | .browser_download_url' | \
    xargs ${SUDO} curl --location --fail --output ${TARGET}/bin/powerline-go
${SUDO} chmod +x ${TARGET}/bin/powerline-go

mkdir -p "${HOME}/.local/etc"
cp "${ROOT}/theme.json" "${HOME}/.local/etc/powerline-go-theme.json"

echo
echo "############################################################"
echo "### Now add something like the following to your ~/.bashrc:"
echo "###"
echo "function _update_ps1() {"
echo "    PS1=\"\$(${TARGET}/bin/powerline-go -theme \${HOME}/.local/etc/powerline-go-theme.json -error \$? -modules exit,user,cwd,git,docker-context,kube,jobs -newline)\""
echo "}"
echo "PROMPT_COMMAND=\"_update_ps1; \$PROMPT_COMMAND\""
echo "############################################################"
echo
