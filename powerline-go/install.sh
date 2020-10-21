#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo justjanne/powerline-go \
    --match suffix \
    --asset -linux-amd64 \
    --type binary \
    --name powerline-go

mkdir -p "${HOME}/.local/etc"
echo "https://pkg.dille.io/powerline-go/theme.json" | \
    download_file | \
    store_file powerline-go-theme.json "${HOME}/.local/etc"

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
