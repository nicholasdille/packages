#!/bin/bash

function require() {
    local package=$1

    if test -z "${package}"; then
        echo "ERROR: Package must be supplied."
        exit 1
    fi

    echo
    echo "### Installing dependency <${package}>..."
    if test -d "$PWD/${package}"; then
        echo "### Installing from local files..."
        bash "$PWD/${package}/install.sh"
    else
        echo "### Installing from remote..."
        curl --silent https://pkg.dille.io/${package}/install.sh | \
            env --unset=SOURCE_LOCAL_FILES bash
    fi
    echo
}

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