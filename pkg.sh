#!/bin/bash

set -o errexit

MY_REPO=nicholasdille/packages
MY_VERSION=master

show_help() {
    echo
    echo "Usage: sh ./pkg.sh <command>"
    echo "       ./pkg.sh <command>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s <command>"
    echo
    echo "Commands:"
    echo "    bootstrap, c   Bootstrap pkg.sh"
    echo "    cache, c       Cache packages.json"
    echo "    file, f        Manage files for a package"
    echo "    help, h        This message"
    echo "    inspect        Inspect a package"
    echo "    install, i     Install a package"
    echo "    list, l        List available packages"
    echo "    search, s      Search packages (name, description and tags)"
    echo "    tags, t        Show tags"
    echo "    version, v     Get installed version"
    echo
}

show_help_bootstrap() {
    echo
    echo "Usage: sh ./pkg.sh bootstrap [--prefix \${HOME}/.local] <string>"
    echo "       ./pkg.sh bootstrap [--prefix \${HOME}/.local] <string>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s bootstrap [--prefix \${HOME}/.local] <string>"
    echo
}

show_help_install() {
    echo
    echo "Usage: sh ./pkg.sh install <package>[,<package>]"
    echo "       ./pkg.sh install <package>[,<package>]"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s install <package>[,<package>]"
    echo
}

show_help_file() {
    echo
    echo "Usage: sh ./pkg.sh file <package> [<file>]"
    echo "       ./pkg.sh file <package> [<file>]"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s file <package> [<>]"
    echo
}

show_help_search() {
    echo
    echo "Usage: sh ./pkg.sh search <string>"
    echo "       ./pkg.sh search <string>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s search <string>"
    echo
}

show_help_version() {
    echo
    echo "Usage: sh ./pkg.sh version <package>"
    echo "       ./pkg.sh version <package>"
    echo "       curl https://pkg.dille.io/pkg.sh | sh -s version <package>"
    echo
}

get_packages() {
    if test -f "${HOME}/.pkg/packages.json"; then
        cat "${HOME}/.pkg/packages.json"

    elif test -f packages.json; then
        >&2 echo "Using local copy of packages.json in current directory. If you are not a contributor, please run <pkg cache>."
        cat packages.json

    else
        >&2 echo "ERROR: Unable to find packages.json. Run <pkg cache> first."
        exit 1
    fi
}

handle_bootstrap() {
    PREFIX="${HOME}/.local"
    while test "$#" -gt 0; do
        param=$1
        shift
        case "${param}" in
            --prefix)
                PREFIX=$1
            ;;
            --help)
                show_help_bootstrap
                exit 0
            ;;
            *)
                show_help_bootstrap
                exit 1
            ;;
        esac
        shift
    done
    
    mkdir -p "${PREFIX}/bin"
    curl --silent --location "https://raw.githubusercontent.com/${MY_REPO}/${MY_VERSION}/pkg.sh" \
        >"${PREFIX}/bin/pkg"
    chmod +x "${PREFIX}/bin/pkg"
}

handle_cache() {
    mkdir -p "${HOME}/.pkg"
    echo "Using version ${TAG}."
    curl --silent "https://api.github.com/repos/${MY_REPO}/releases/tags/${TAG}" | \
        jq --raw-output '.assets[] | select(.name == "packages.json") | .browser_download_url' | \
        xargs curl --silent --location --output "${HOME}/.pkg/packages.json"
}

handle_file() {
    package=$1

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        show_help_file
        exit 1
    fi

    shift
    file=$1
    if test -z "${file}"; then
        get_packages | \
            jq --raw-output --arg package "${package}" '
                .packages[] |
                select(.name == $package) |
                .files[]
            '
    else
        if test -f "${package}/${file}"; then
            >&2 echo "Using local file"
            cat "${package}/${file}"
        else
            >&2 echo "Downloading file"
            curl --silent "https://pkg.dille.io/${package}/${file}"
        fi
    fi
}

handle_inspect() {
    package=$1

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        show_help_install
        exit 1
    fi

    get_packages | \
        jq --arg package "${package}" '.packages[] | select(.name == $package)'
}

handle_install() {
    if test "$#" -eq 0; then
        echo "ERROR: No package specified."
        show_help_install
        exit 1
    fi

    for package_spec in "$@"; do
        local package
        package=$(echo "${package_spec}" | cut -d@ -f1)
        local requested_version
        requested_version=$(echo "${package_spec}" | cut -d@ -f2)
        if test "${requested_version}" == "${package}"; then
            unset requested_version
        fi

        working_directory="${PWD}"

        # shellcheck source=.scripts/variables.sh
        source "${HOME}/.pkg/variables.sh"
        # shellcheck source=.scripts/control.sh
        source "${HOME}/.pkg/control.sh"
        # shellcheck source=.scripts/linux.sh
        source "${HOME}/.pkg/linux.sh"
        # shellcheck source=.scripts/github.sh
        source "${HOME}/.pkg/github.sh"
        # shellcheck source=.scripts/codeberg.sh
        source "${HOME}/.pkg/codeberg.sh"
        # shellcheck source=.scripts/docker.sh
        source "${HOME}/.pkg/docker.sh"

        check_installed_version "${package}"
        if package_needs_docker "${package}"; then
            check_docker
        fi
        unlock_sudo

        latest_version=$(get_latest_version "${package}")
        if test -z "${requested_version}"; then
            requested_version="${latest_version}"
        fi

        echo "Installing ${package} version ${requested_version}..."

        eval "$(get_install_script "${package}")"

        echo "Finished installation of ${package} version ${requested_version}."
    done
}

handle_list() {
    get_packages | \
        jq --raw-output '
            .packages[] |
            "\(.name);\(.description)"
        ' | \
        uniq | \
        sort | \
        column -t -s ';'
}

handle_search() {
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
                    .packages[] |
                    select(.name | ascii_downcase | contains($search | ascii_downcase)) |
                    "\(.name);\(.description)"
                '
        fi
        if ${SEARCH_DESC}; then
            echo "${PACKAGES}" | \
                jq --raw-output --arg search "${SEARCH_TERM}" '
                    .packages[] |
                    select(.description | ascii_downcase | contains($search | ascii_downcase)) |
                    "\(.name);\(.description)"
                '
        fi
        if ${SEARCH_TAGS}; then
            echo "${PACKAGES}" | \
                jq --raw-output --arg search "${SEARCH_TERM}" '
                    .packages[] |
                    select(.tags[] | contains($search | ascii_downcase)) |
                    "\(.name);\(.description)"
                '
        fi
    ) | \
    sort | \
    uniq | \
    column -t -s ';'
}

handle_tags() {
    get_packages | \
        jq --raw-output '.packages[].tags[]' | \
        sort | \
        uniq
}

handle_version() {
    package=$1

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        show_help_version
        exit 1
    fi

    package_json=$(
        get_packages | \
            jq --raw-output --arg package "${package}" '
                .packages[] |
                select(.name == $package)
            '
    )

    version_command=$(
        echo "${package_json}" | \
            jq --raw-output '.version.command'
    )
    if test -z "${version_command}" || test "${version_command}" == "null"; then
        >&2 echo "ERROR: No version command specified for package <${package}>."
        return
    fi

    version_filter=$(
        echo "${package_json}" | \
            jq --raw-output '.version.filter'
    )
    if test -z "${version_filter}" || test "${version_filter}" == "null"; then
        >&2 echo "ERROR: No version filter specified for package <${package}>."
        return
    fi

    version_pattern=$(
        echo "${package_json}" | \
            jq --raw-output '.version.pattern'
    )
    if test -z "${version_pattern}" || test "${version_pattern}" == "null"; then
        >&2 echo "ERROR: No version pattern specified for package <${package}>."
        return
    fi

    ${version_command} 2>/dev/null | \
        grep "${version_filter}" | \
        sed -E "${version_pattern}"
}

prepare() {
    mkdir -p "${HOME}/.pkg"
    for lib in variables codeberg control docker github linux; do
        if ! test -f "${HOME}/.pkg/${lib}.sh"; then
            curl "https://github.com/${MY_REPO}/raw/${MY_VERSION}/.scripts/${lib}.sh" \
                --silent \
                --location  \
                >"${HOME}/.pkg/${lib}.sh"
        fi
    done

    : "${VERSION:=latest}"
    if test -z "${TAG}"; then
        # shellcheck source=.scripts/github.sh
        source "${HOME}/.pkg/github.sh"
        TAG=$(
            github_get_releases "${MY_REPO}" | \
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
                handle_cache "$@"
                exit 0
            ;;
            bootstrap|b)
                prepare
                handle_bootstrap "$@"
                exit 0
            ;;
            file|f)
                prepare
                handle_file "$@"
                exit 0
            ;;
            inspect)
                prepare
                handle_inspect "$@"
                exit 0
            ;;
            install|i)
                prepare
                handle_install "$@"
                exit 0
            ;;
            list|l)
                prepare
                handle_list "$@"
                exit 0
            ;;
            search|s)
                prepare
                handle_search "$@"
                exit 0
            ;;
            tags|t)
                prepare
                handle_tags "$@"
                exit 0
            ;;
            version|v)
                prepare
                handle_version "$@"
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
