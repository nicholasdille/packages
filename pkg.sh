#!/bin/sh

set -o errexit

MY_REPO=nicholasdille/packages

function show_help() {
    echo "Usage: sh ./pkg.sh <command>"
    echo "       ./pkg.sh <command>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s <command>"
    echo
    echo "Commands:"
    echo "    help, h       XXX"
    echo "    install, i    XXX"
    echo "    list, l       XXX"
    echo "    search, s     XXX"
    echo "    tags, t       XXX"
    echo
}

function get_packages() {
    if test -f packages.json; then
        cat packages.json
    else
        curl --silent https://api.github.com/repos/${MY_REPO}/releases/tags/${TAG} | \
            jq --raw-output '.assets[] | select(.name == "packages.json")'
    fi
}

function install() {
    curl --silent https://pkg.dille.io/$1/install.sh | sh
}

function list() {
    get_packages | \
        jq --raw-output '
            .tools[] | 
            "\(.name)\t\(.description)"
        '
}

function search() {
    get_packages | \
        jq --raw-output --arg search $1 '
            .tools[] | 
            select(.name | ascii_downcase | contains($search | ascii_downcase)) | 
            "\(.name)\t\(.description)"
        '

    get_packages | \
        jq --raw-output --arg search $1 '
            .tools[] | 
            select(.description | ascii_downcase | contains($search | ascii_downcase)) | 
            "\(.name)\t\(.description)"
        '

    get_packages | \
        jq --raw-output --arg search $1 '
            .tools[] | 
            select(.tags[] | contains($search | ascii_downcase)) | 
            "\(.name)\t\(.description)"
        '
}

function tags() {
    get_packages | \
        jq --raw-output --arg search container '.tools[].tags[] | unique | sort'
}

function prepare() {
    : "${VERSION:=latest}"
    if test -z "${TAG}"; then
        TAG=$(
                curl --silent https://api.github.com/repos/${MY_REPO}/releases | \
                    jq --raw-output 'map(select(.tag_name | startswith("packages/"))) | .[0].tag_name'
            )
    fi
    if test -z "${TAG}"; then
        echo "ERROR: Failed to determine tag from version ${VERSION}."
        exit 1
    fi
}

function main() {
    while test "$#" -gt 0; do
        param=$1
        shift
        case "${param}" in
            help|h)
                show_help
            ;;
            --version|-v)
                VERSION=$1   
            ;;
            install|i)
                prepare
                install "$@"
            ;;
            list|l)
                prepare
                list "$@"
            ;;
            search|s)
                prepare
                search "$@"
            ;;
            tags|t)
                prepare
                tags "$@"
            ;;
        esac
        shift
    done
}

case "$0" in
    -bash)
        echo "ERROR: Do not source this script."
    ;;
    bash)
        EXECUTION_TYPE=pipe
        main "$@"
    ;;
    *)
        EXECUTION_TYPE=script
        main "$@"
    ;;
esac

set +o errexit
