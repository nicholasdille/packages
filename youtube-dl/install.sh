#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

TAG=$(
    codeberg_get_tags polarisfm/youtube-dl | \
        codeberg_select_latest_tag
)
if test -z "${TAG}"; then
    echo "ERROR: Unable to determine version to install."
    exit 1
fi

build_containerized python <<EOF
apt-get update
apt-get -y install zip pandoc
git clone https://codeberg.org/polarisfm/youtube-dl /tmp/youtube-dl
cd /tmp/youtube-dl
git checkout "${TAG}"
make youtube-dl youtube-dl.1 youtube-dl.bash-completion
ls -l
cp youtube-dl youtube-dl.1 youtube-dl.bash-completion /
EOF
extract_file_from_container youtube-dl

# shellcheck disable=SC2154
docker cp "${container_name}:/youtube-dl.1" - | \
    tar -x --to-stdout | \
    sudo tee "${TARGET_BASE}/share/man/man1/youtube-dl.1" >/dev/null

# shellcheck disable=SC2154
docker cp "${container_name}:/youtube-dl.bash-completion" - | \
    tar -x --to-stdout | \
    store_completion youtube-dl
