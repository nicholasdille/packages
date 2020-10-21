#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

if ! test -d "${HOME}/.rbenv"; then
    git clone https://github.com/rbenv/rbenv "${HOME}/.rbenv"
fi
export PATH="${HOME}/.rbenv/shims:${HOME}/.rbenv/bin:${PATH}"
if ! test -d "$(rbenv root)/plugins/ruby-build"; then
    git clone https://github.com/rbenv/ruby-build "$(rbenv root)/plugins/ruby-build"
fi

curl --silent --location https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash

export DOCKER_BUILDKIT=1
curl --silent https://pkg.dille.io/rbenv/Dockerfile | \
    docker build --tag rbenv -

echo
echo "#############################################"
echo "### Now add the following to your ~/.bashrc:"
echo "###"
echo "export PATH=\${HOME}/.rbenv/bin:\${PATH}"
echo "eval $(rbenv init -)"
echo "#############################################"
echo

echo
echo "#################################################"
echo "### For building from source, use the following:"
echo "###"
echo "docker run -it --rm --name rbenv --env HOME --env PATH --volume ${HOME}:${HOME} --workdir ${HOME} --user $(id -u):$(id -g) rbenv rbenv"
echo "#################################################"
echo
