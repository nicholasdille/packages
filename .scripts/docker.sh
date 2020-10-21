#!/bin/bash

container_name=$(basename "$(mktemp --dry-run)")
docker_clean() {
    echo "Cleaning up temporary container..."
    docker ps --all --quiet --filter name="${container_name}" | xargs --no-run-if-empty docker rm
}
trap docker_clean EXIT

function check_docker() {
    if ! type docker >/dev/null 2>&1; then
        echo "ERROR: Docker is required but was not found."
        exit 1
    fi
    if ! docker version >/dev/null 2>&1; then
        echo "ERROR: Docker daemon is not running"
        exit 1
    fi
}

function build_containerized() {
    local image=$1
    shift
    local command=("$@")

    if test -z "${image}"; then
        echo "ERROR: Image not specified."
        exit 1
    fi
    if test "${#command[@]}" == 0; then
        command=("bash" "-xe")
    fi

    cat | \
        docker run -i --name "${container_name}" "${image}" "${command[@]}"
}

function extract_file_from_container() {
    while test -n "$1"; do
        docker cp "${container_name}:/$1" - | ${SUDO} tar -xvC "${TARGET_BIN}"
        shift
    done
}