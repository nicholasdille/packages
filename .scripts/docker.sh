#!/bin/bash

function check_docker() {
    if ! type docker 2>&1 /dev/null; then
        echo "ERROR: Docker is required but was not found."
        exit 1
    fi
}