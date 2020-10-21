#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://dl.k8s.io/release/stable.txt | \
    xargs -I${SUDO} {} ${SUDO} curl --location --output ${TARGET}/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/{}/bin/linux/amd64/kubectl
${SUDO} chmod +x ${TARGET}/bin/kubectl

${SUDO} mkdir -p ${TARGET}/etc/bash_completion.d
kubectl completion bash | ${SUDO} tee ${TARGET}/etc/bash_completion.d/kubectl.sh >/dev/null
${SUDO} ln -sf ${TARGET}/etc/bash_completion.d/kubectl.sh /etc/bash_completion.d/
