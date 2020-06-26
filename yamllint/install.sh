#!/bin/bash

set -o errexit

ROOT=$(dirname $(readlink -f "$0"))

pip install --user yamllint

mkdir ~/.config/yamllint/
cp ${ROOT}/yamllint.yaml ~/.config/yamllint/config
