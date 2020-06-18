#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

go get github.com/krishicks/yaml-patch/cmd/yaml-patch
