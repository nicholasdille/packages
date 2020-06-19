#!/bin/bash

set -o errexit

: "${TARGET:=/usr/local}"

go get github.com/krishicks/yaml-patch/cmd/yaml-patch
