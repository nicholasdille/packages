#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

git clone https://github.com/moovweb/gvm "${HOME}/.gvm"

export DOCKER_BUILDKIT=1
docker build --tag gvm 

echo
echo "#############################################"
echo "### Now add the following to your ~/.bashrc:"
echo "###"
echo "export GVM_ROOT=\${HOME}/.gvm"
echo "source \$GVM_ROOT/scripts/gvm-default"
echo "#############################################"
echo
