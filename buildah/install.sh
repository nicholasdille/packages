#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_docker
unlock_sudo

TAG=$(
    github_find_latest_release containers/buildah | \
    jq --raw-output '.tag_name'
)

build_containerized golang:1.12 <<EOF
apt-get update
#apt-get -y install --no-install-recommends software-properties-common
#add-apt-repository -y ppa:alexlarsson/flatpak
#add-apt-repository -y ppa:gophers/archive
#add-apt-repository -y ppa:projectatomic/ppa
apt-get -y -qq update
apt-get -y install --no-install-recommends \
    bats \
    btrfs-tools \
    libapparmor-dev \
    libdevmapper-dev \
    libglib2.0-dev \
    libgpgme11-dev \
    libseccomp-dev \
    libselinux1-dev \
    go-md2man
mkdir ~/buildah
cd ~/buildah
export GOPATH=$(pwd)
git clone https://github.com/containers/buildah ./src/github.com/containers/buildah
cd ./src/github.com/containers/buildah
git checkout ${TAG}
make runc all SECURITYTAGS="apparmor seccomp"
#whereis buildah
# copy buildah
#cp docs/cni-examples/*.conf /
EOF
#docker cp buildah:/buildah - | ${SUDO} tar -xvC ${TARGET_BIN}
#mkdir -p /etc/cni/net.d
#docker cp buildah:/*.conf - | ${SUDO} tar -xvC ${TARGET_BASE}/etc/cni/net.d
#${SUDO} chmod 0644 /etc/cni/net.d/*.conf
