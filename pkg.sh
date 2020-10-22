#!/bin/sh

set -o errexit

MY_REPO=nicholasdille/packages

show_help() {
    echo
    echo "Usage: sh ./pkg.sh <command>"
    echo "       ./pkg.sh <command>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s <command>"
    echo
    echo "Commands:"
    echo "    cache, c      Cache packages.json"
    echo "    help, h       This message"
    echo "    inspect       Inspect a package"
    echo "    install, i    Install a package"
    echo "    list, l       List available packages"
    echo "    search, s     Search packages (name, description and tags)"
    echo "    tags, t       Show tags"
    echo
}

show_help_install() {
    echo
    echo "Usage: sh ./pkg.sh install <package>"
    echo "       ./pkg.sh install <package>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s install <package>"
    echo
}

show_help_search() {
    echo
    echo "Usage: sh ./pkg.sh search <string>"
    echo "       ./pkg.sh search <string>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s search <string>"
    echo
}

get_packages() {
    if test -f "${HOME}/.pkg/packages.json"; then
        cat "${HOME}/.pkg/packages.json"
    elif test -f packages.json; then
        cat packages.json
    else
        echo "ERROR: Unable to find packages.json. Run <pkg cache> first."
        exit 1
    fi
}

cache() {
    mkdir -p "${HOME}/.pkg"
    echo "Using version ${TAG}."
    curl --silent "https://api.github.com/repos/${MY_REPO}/releases/tags/${TAG}" | \
        jq --raw-output '.assets[] | select(.name == "packages.json") | .browser_download_url' | \
        xargs curl --silent --location --output "${HOME}/.pkg/packages.json"
}

inspect() {
    package=$1

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        show_help_install
        exit 1
    fi

    curl --silent "https://pkg.dille.io/${package}/package.yaml"
}

install() {
    package=$1

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        show_help_install
        exit 1
    fi

    curl --silent "https://pkg.dille.io/${package}/install.sh" | bash
}

list() {
    get_packages | \
        jq --raw-output '
            .tools[] | 
            "\(.name);\(.description)"
        ' | \
        uniq | \
        sort | \
        column -t -s ';'
}

search() {
    SEARCH_TERM=""
    SEARCH_NAME=false
    SEARCH_DESC=false
    SEARCH_TAGS=false
    while test "$#" -gt 0; do
        case "$1" in
            --name)
                SEARCH_NAME=true
            ;;
            --desc)
                SEARCH_DESC=true
            ;;
            --tags)
                SEARCH_TAGS=true
            ;;
            *)
                if test -z "${SEARCH_TERM}"; then
                    SEARCH_TERM=$1
                fi
            ;;
        esac
        shift
    done

    if test -z "${SEARCH_TERM}"; then
        echo "ERROR: No search term specified."
        show_help_search
        exit 1
    fi
    if ! ${SEARCH_NAME} && ! ${SEARCH_DESC} && ! ${SEARCH_TAGS}; then
        SEARCH_NAME=true
        SEARCH_DESC=true
        SEARCH_TAGS=true
    fi

    PACKAGES=$(get_packages)
    (
        if ${SEARCH_NAME}; then
            echo "${PACKAGES}" | \
                jq --raw-output --arg search "${SEARCH_TERM}" '
                    .tools[] | 
                    select(.name | ascii_downcase | contains($search | ascii_downcase)) |
                    "\(.name);\(.description)"
                '
        fi
        if ${SEARCH_DESC}; then
            echo "${PACKAGES}" | \
                jq --raw-output --arg search "${SEARCH_TERM}" '
                    .tools[] | 
                    select(.description | ascii_downcase | contains($search | ascii_downcase)) | 
                    "\(.name);\(.description)"
                '
        fi
        if ${SEARCH_TAGS}; then
            echo "${PACKAGES}" | \
                jq --raw-output --arg search "${SEARCH_TERM}" '
                    .tools[] | 
                    select(.tags[] | contains($search | ascii_downcase)) |
                    "\(.name);\(.description)"
                '
        fi
    ) | \
    sort | \
    uniq | \
    column -t -s ';'
}

tags() {
    get_packages | \
        jq --raw-output '.tools[].tags[]' | \
        sort | \
        uniq
}

prepare() {
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

main() {
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
            cache|c)
                prepare
                cache "$@"
                exit 0
            ;;
            inspect)
                prepare
                inspect "$@"
                exit 0
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
        # Was started using "source pkg.sh"
        echo "ERROR: Do not source this script."
    ;;
    bash)
        # Was started using "bash pkg.sh"
        main "$@"
    ;;
    *)
        # Was started using "./pkg.sh"
        main "$@"
    ;;
esac

set +o errexit
