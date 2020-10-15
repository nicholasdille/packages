#!/bin/bash

set -o errexit

ROOT=$(dirname "$(readlink -f "$0")")

pip install --user yamllint

mkdir "${HOME}/.config/yamllint/"
cp "${ROOT}/yamllint.yaml" "${HOME}/.config/yamllint/config"
