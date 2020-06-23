#!/bin/bash

clean() {
    docker rm buildah
}

trap clean EXIT

: "${TARGET:=/usr/local}"

TAG_NAME=$(curl --silent https://api.github.com/repos/containers/buildah/releases/latest | jq --raw-output '.tag_name')
if test -z "${TAG_NAME}"; then
    echo "ERROR: Unable to determine tag name"
    exit 1
fi

docker run -i --name buildah golang:1.12 bash -e <<EOF
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
export GOPATH=`pwd`
git clone https://github.com/containers/buildah ./src/github.com/containers/buildah
cd ./src/github.com/containers/buildah
git checkout ${TAG_NAME}
make runc all SECURITYTAGS="apparmor seccomp"
#whereis buildah
# copy buildah
#cp docs/cni-examples/*.conf /
EOF
#docker cp buildah:/buildah - | sudo tar -xvC ${TARGET}/bin/
#mkdir -p /etc/cni/net.d
#docker cp buildah:/*.conf - | sudo tar -xvC ${TARGET}/etc/cni/net.d
#sudo chmod 0644 /etc/cni/net.d/*.conf
