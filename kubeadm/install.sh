#!/bin/bash

set -o errexit

# shellcheck source=.scripts/source.sh
source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

check_installed_version
unlock_sudo

echo "https://dl.k8s.io/release/stable.txt" | \
    download_file | \
    xargs -I{} echo "https://storage.googleapis.com/kubernetes-release/release/{}/bin/linux/amd64/kubeadm" | \
    download_file | \
    store_file kubeadm | \
    make_executable

kubeadm completion bash | \
    store_completion kubeadm
