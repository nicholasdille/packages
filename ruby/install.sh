#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

require rbenv

TAG=$(
    github_get_tags ruby/ruby | \
        jq --raw-output '.[].ref' | \
        cut -d/ -f3 | \
        grep -E "^v[0-9]+_[0-9]+_[0-9]+$" | \
        tr '_' '.' | \
        sort -V -r | \
        head -n 1
)

export PATH="${HOME}/.rbenv/bin:${PATH}"
eval "$(rbenv init -)"
docker run -it --rm --name rbenv \
    --env HOME \
    --env PATH \
    --volume "${HOME}:${HOME}" \
    --workdir "${HOME}" \
    --user "$(id -u):$(id -g)" \
    rbenv \
    rbenv install "${TAG#v}" --skip-existing
rbenv rehash

echo
echo "#############################################"
echo "### Now add the following to your ~/.bashrc:"
echo "###"
echo "export PATH=\${HOME}/.rbenv/versions/${TAG#v}/bin:\${PATH}"
echo "#############################################"
echo
