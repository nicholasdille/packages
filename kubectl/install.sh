#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt | \
    xargs -I{} sudo curl -Lo ${TARGET}/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/{}/bin/linux/amd64/kubectl
sudo chmod +x ${TARGET}/bin/kubectl

#cat >>~/.bashrc <<EOF
#source <(kubectl completion bash)
#alias k=kubectl
#complete -F __start_kubectl k
#EOF
