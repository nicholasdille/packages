#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

TAG=$(
    github_find_latest_release nvm-sh/nvm | \
        jq --raw-output '.tag_name'
)

git clone https://github.com/nvm-sh/nvm "${HOME}/.nvm"
pushd "${HOME}/.nvm"
git checkout "${TAG}"
popd

echo
echo "#############################################"
echo "### Now add the following to your ~/.bashrc:"
echo "###"
echo "export NVM_DIR=\${HOME}/.nvm"
echo "source \${NVM_DIR}/nvm.sh"
echo "#############################################"
echo
