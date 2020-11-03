#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

if ! test -d "${TARGET_BASE}/gvm"; then
    ${SUDO} git clone https://github.com/moovweb/gvm "${TARGET_BASE}/gvm"
fi

export DOCKER_BUILDKIT=1
curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file "${PACKAGE}" Dockerfile | \
    docker build --tag gvm -

# shellcheck disable=SC2016
curl --silent https://pkg.dille.io/pkg.sh | \
    bash -s file "${PACKAGE}" profile.d.gvm.sh | \
    TARGET_BASE=${TARGET_BASE} envsubst '${TARGET_BASE}' | \
    store_file gvm.sh /etc/profile.d

echo
echo "#################################################"
echo "### For building from source, use the following:"
echo "###"
echo "docker run -it --rm --name gvm --env GVM_ROOT --env PATH --volume ${TARGET_BASE}/gvm:${TARGET_BASE}/gvm gvm gvm"
echo "#################################################"
echo
