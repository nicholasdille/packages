#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

go get -u github.com/cloudflare/cloudflare-go/cmd/flarectl
