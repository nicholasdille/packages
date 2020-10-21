#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://dl.k8s.io/release/stable.txt | \
    xargs -I{} ${SUDO} curl --location --output ${TARGET}/bin/kubeadm https://storage.googleapis.com/kubernetes-release/release/{}/bin/linux/amd64/kubeadm
${SUDO} chmod +x ${TARGET}/bin/kubeadm
