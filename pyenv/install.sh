#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

if ! test -d "${TARGET_BASE}/pyenv"; then
    ${SUDO} git clone https://github.com/pyenv/pyenv.git "${TARGET_BASE}/pyenv"
fi
export PYENV_ROOT="${TARGET_BASE}/pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"
if ! test -d "${PYENV_ROOT}/plugins/pyenv-virtualenv"; then
    ${SUDO} git clone https://github.com/pyenv/pyenv-virtualenv.git "${PYENV_ROOT}/plugins/pyenv-virtualenv"
fi
if ! test -d "${PYENV_ROOT}/plugins/pyenv-doctor"; then
    ${SUDO} git clone https://github.com/pyenv/pyenv-doctor.git "${PYENV_ROOT}/plugins/pyenv-doctor"
fi

export DOCKER_BUILDKIT=1
curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file pyenv Dockerfile | \
    docker build --tag pyenv -

docker run --rm --name pyenv \
    --env PYENV \
    --env HOME \
    --env PATH \
    --volume "${TARGET_BASE}/pyenv:${TARGET_BASE}/pyenv" \
    pyenv \
    pyenv doctor

curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file pyenv profile.d.pyenv.sh | \
    TARGET_BASE=${TARGET_BASE} envsubst '${TARGET_BASE}' | \
    store_file pyenv.sh /etc/profile.d

echo
echo "#################################################"
echo "### For building from source, use the following:"
echo "###"
echo "docker run -it --rm --name pyenv --env PYENV --env HOME --env PATH --volume ${HOME}:${HOME} --workdir ${HOME} --user $(id -u):$(id -g) pyenv pyenv"
echo "#################################################"
echo
