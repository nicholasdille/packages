#!/bin/bash

set -o errexit

clean() {
    rm -rf "${MKTEMP}"
}

trap clean EXIT

: "${TARGET:=/usr/local}"

MKTEMP=$(mktemp --directory)
git clone https://github.com/weaveworks/kubediff "${MKTEMP}"
cd "${MKTEMP}"
pip install .
pip install -r requirements.txt
${SUDO} cp kubediff "${TARGET}/bin/"
