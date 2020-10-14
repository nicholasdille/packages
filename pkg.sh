#!/bin/sh

set -o errexit

MY_REPO=nicholasdille/packages

function show_help() {
    echo
    echo "Usage: sh ./pkg.sh <command>"
    echo "       ./pkg.sh <command>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s <command>"
    echo
    echo "Commands:"
    echo "    help, h       This message"
    echo "    install, i    Install a package"
    echo "    list, l       List available packages"
    echo "    search, s     Search packages (name, description and tags)"
    echo "    tags, t       Show tags"
    echo
}

function show_help_install() {
    echo
    echo "Usage: sh ./pkg.sh install <package>"
    echo "       ./pkg.sh install <package>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s install <package>"
    echo
}

function show_help_search() {
    echo
    echo "Usage: sh ./pkg.sh search <string>"
    echo "       ./pkg.sh search <string>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s search <string>"
    echo
}

function get_packages() {
    if test -f packages.json; then
        cat packages.json
    else
        curl --silent https://api.github.com/repos/${MY_REPO}/releases/tags/${TAG} | \
            jq --raw-output '.assets[] | select(.name == "packages.json") | .browser_download_url' | \
            xargs curl --silent --location
    fi
}

function install() {
    local package=$1

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        show_help_install
        exit 1
    fi

    curl --silent https://pkg.dille.io/${package}/install.sh | bash
}

function list() {
    get_packages | \
        jq --raw-output '
            .tools[] | 
            "\(.name);\(.description)"
        ' | \
        uniq | \
        sort | \
        column -t -s ';'
}

function search() {
    local search=$1

    if test -z "${search}"; then
        echo "ERROR: No search term specified."
        show_help_search
        exit 1
    fi

    PACKAGES=$(get_packages)

    (
        echo "${PACKAGES}" | \
            jq --raw-output --arg search ${search} '
                .tools[] | 
                select(.name | ascii_downcase | contains($search | ascii_downcase)) |
                "\(.name);\(.description)"
            '
        echo "${PACKAGES}" | \
            jq --raw-output --arg search ${search} '
                .tools[] | 
                select(.description | ascii_downcase | contains($search | ascii_downcase)) | 
                "\(.name);\(.description)"
            '
        echo "${PACKAGES}" | \
            jq --raw-output --arg search ${search} '
                .tools[] | 
                select(.tags[] | contains($search | ascii_downcase)) |
                "\(.name);\(.description)"
            '
    ) | \
    uniq | \
    sort | \
    column -t -s ';'
}

function tags() {
    get_packages | \
        jq --raw-output '.tools[].tags[]' | \
        uniq | \
        sort
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
    if test "$#" -eq 0; then
        show_help
        exit 0
    fi

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
                exit 0
            ;;
            list|l)
                prepare
                list "$@"
                exit 0
            ;;
            search|s)
                prepare
                search "$@"
                exit 0
            ;;
            tags|t)
                prepare
                tags "$@"
                exit 0
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
