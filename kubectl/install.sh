#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

curl --silent https://storage.googleapis.com/kubernetes-release/release/stable.txt | \
    xargs -I{} sudo curl --location --output ${TARGET}/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/{}/bin/linux/amd64/kubectl
sudo chmod +x ${TARGET}/bin/kubectl

sudo mkdir -p ${TARGET}/etc/bash_completion.d
kubectl completion bash | sudo tee ${TARGET}/etc/bash_completion.d/kubectl.sh >/dev/null
sudo ln -s ${TARGET}/etc/bash_completion.d/kubectl.sh /etc/bash_completion.d/

#alias k=kubectl
#complete -F __start_kubectl k
