#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

if ! test -d "${HOME}/.pyenv"; then
    git clone https://github.com/pyenv/pyenv.git "${HOME}/.pyenv"
fi
export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"
if ! test -d "$(pyenv root)/plugins/pyenv-virtualenv"; then
    git clone https://github.com/pyenv/pyenv-virtualenv.git "$(pyenv root)/plugins/pyenv-virtualenv"
fi

export DOCKER_BUILDKIT=1
curl --silent https://pkg.dille.io/gvm/Dockerfile | \
    docker build --tag pyenv -

echo
echo "#############################################"
echo "### Now add the following to your ~/.bashrc:"
echo "###"
echo "export PYENV_ROOT=\$HOME/.pyenv"
echo "export PATH=\$PYENV_ROOT/bin:\$PATH"
echo "eval \$(pyenv init -)"
echo "eval \$(pyenv virtualenv-init -)"
echo "#############################################"
echo
