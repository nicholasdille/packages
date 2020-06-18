#!/bin/bash

set -o errexit

BASE=$(dirname $(readlink -f "$0"))
source ${BASE}/../common.sh

go get -d github.com/mayflower/docker-ls/cli/...
go generate github.com/mayflower/docker-ls/lib/...
go install github.com/mayflower/docker-ls/cli/...
