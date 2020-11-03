#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

if ! test -d "${TARGET_BASE}/rbenv"; then
    ${SUDO} git clone https://github.com/rbenv/rbenv "${TARGET_BASE}/rbenv"
fi
export PATH="${TARGET_BASE}/rbenv/shims:${TARGET_BASE}/rbenv/bin:${PATH}"
if ! test -d "${TARGET_BASE}/rbenv/plugins/ruby-build"; then
    ${SUDO} git clone https://github.com/rbenv/ruby-build "${TARGET_BASE}/rbenv/plugins/ruby-build"
fi
curl --silent --location https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash

export DOCKER_BUILDKIT=1
curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file rbenv Dockerfile | \
    docker build --tag rbenv -

curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file rbenv profile.d.rbenv.sh | \
    envsubst '${TARGET_BASE}' | \
    store_file rbenv.sh /etc/profile.d/

echo
echo "#################################################"
echo "### For building from source, use the following:"
echo "###"
echo "docker run -it --rm --name rbenv --env PATH --volume ${TARGET_BASE}/rbenv:${TARGET_BASE}/rbenv rbenv rbenv"
echo "#################################################"
echo
