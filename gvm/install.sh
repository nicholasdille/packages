#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

if ! test -d "${HOME}/.gvm"; then
    git clone https://github.com/moovweb/gvm "${HOME}/.gvm"
fi

export DOCKER_BUILDKIT=1
curl --silent https://pkg.dille.io/gvm/Dockerfile | \
    docker build --tag gvm -

echo
echo "#############################################"
echo "### Now add the following to your ~/.bashrc:"
echo "###"
echo "export GVM_ROOT=\${HOME}/.gvm"
echo "source \$GVM_ROOT/scripts/gvm-default"
echo "#############################################"
echo
