#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

${SUDO} apt-get update
${SUDO} apt-get -y install bpfcc-tools

github_install \
    --repo aquasecurity/tracee \
    --match name \
    --asset tracee.tar.gz \
    --type tarball \
    --include tracee
