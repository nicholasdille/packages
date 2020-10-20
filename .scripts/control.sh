#!/bin/bash

#info "Creating temporary directory..."
export PACKAGES_TEMP_DIR
PACKAGES_TEMP_DIR=$(mktemp --directory --suffix -packages)
chmod 0700 "${PACKAGES_TEMP_DIR}"

export PACKAGES_CLEANUP_FUNCTIONS
PACKAGES_CLEANUP_FUNCTIONS=()

function clean_temp_dir() {
    log INFO "Cleaning temporary directory"
    rm -rf "${PACKAGES_TEMP_DIR}"
    unset PACKAGES_TEMP_DIR
}
PACKAGES_CLEANUP_FUNCTIONS+=("clean_temp_dir")

function clean() {
    for FUNCTION in ${PACKAGES_CLEANUP_FUNCTIONS[*]}; do
        "${FUNCTION}"
    done
}
trap clean EXIT

function add_prefix() {
    local prefix=$1

    if test -z "${prefix}"; then
        echo "ERROR: Prefix must be supplied."
        exit 1
    fi

    cat | while read -r LINE; do
        echo "${prefix}: ${LINE}"
    done
}

function run_filters() {
    local filters=("$@")

    # slurp input
    data=$(cat | jq --slurp --raw-input --raw-output --compact-output --monochrome-output .)

    for i in ${!filters[*]}; do
        >&2 echo "Applying filter $i <${filters[$i]}>..."

        # apply filter and store output
        data=$(echo -n "${data}" | eval "${filters[$i]}")
    done
    echo "${data}"
}

function run_tasks() {
    local tasks=("$@")

    # slurp input
    data=$(cat | jq --slurp --raw-input --raw-output --compact-output --monochrome-output .)

    >&2 echo
    for i in ${!tasks[*]}; do
        >&2 echo "Running task $i"
        echo -n "${data}" | eval "${tasks[$i]}"
        >&2 echo
    done
}