#!/bin/bash

# shellcheck disable=SC1091
source /usr/local/bin/kube-ps1.sh
PS1='[\u@\h \W $(kube_ps1)]\$ '
