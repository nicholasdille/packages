#!/bin/bash

GITHUB_AUTH_PARAMETER=()
if test -n "${GITHUB_USER}" && test -n "${GITHUB_TOKEN}"; then
    >&2 echo "Using authentication for GitHub"
    GITHUB_AUTH_PARAMETER=("--user" "${GITHUB_USER}:${GITHUB_TOKEN}")
fi

function github_api() {
    local path=$1

    curl "https://api.github.com${path}" \
            "${GITHUB_AUTH_PARAMETER[@]}" \
            --silent
}

function github_api_repo() {
    local project=$1
    local path=$2

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    github_api "/repos/${project}${path}"
}

function github_rate_limit_ok() {
    eval "$(
        github_api /rate_limit | \
        jq \
            --raw-output '
                "
                export GITHUB_RATE_LIMIT=\(.rate.limit)\n
                export GITHUB_RATE_REMAINING=\(.rate.remaining)\n
                export GITHUB_RATE_RESET=\(.rate.reset)
                "
            '
    )"
    
    >&2 echo "VERBOSE: GitHub rate limit ${GITHUB_RATE_REMAINING}/${GITHUB_RATE_LIMIT} remaining"
    if test "${GITHUB_RATE_REMAINING}" -eq 0; then
        >&2 echo "WARNING: GitHub rate limit exceeded (resets as $(date -d "@${GITHUB_RATE_RESET}"))"
        return 1
    fi

    return 0
}

function github_check_rate_limit() {
    if ! github_rate_limit_ok; then
        >&2 echo "ERROR: GitHub rate limit exceeded"
        exit 1
    fi
}

function github_get_repo_description() {
    local project=$1

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    >&2 echo "Fetching description for ${project}..."
    github_api_repo "${project}" "" | \
        jq --raw-output '.description'
}

function github_get_releases() {
    local project=$1

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    >&2 echo "Fetching releases for ${project}..."
    github_api_repo "${project}" "/releases"
}

function github_get_release() {
    local project=$1
    local version=$2
    : "${version:=${requested_version}}"

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    if test -z "${version}"; then
        echo "ERROR: Release not specified."
        return 1
    fi

    >&2 echo "Fetching release ${version} for ${project}..."
    github_api_repo "${project}" "/releases/tags/${version}"
}

function github_resolve_assets() {
    jq --raw-output --compact-output --monochrome-output '.assets[]'
}

function github_select_asset_by_name() {
    local asset_name=$1

    if test -z "${asset_name}"; then
        echo "ERROR: Asset name not specified."
        return 1
    fi

    >&2 echo "Selecting asset by name <${asset_name}>..."
    cat | \
        jq --raw-output --compact-output --monochrome-output --arg asset_name "${asset_name}" 'select(.name == $asset_name)'
}

function github_select_asset_by_suffix() {
    local asset_name_suffix=$1

    if test -z "${asset_name_suffix}"; then
        echo "ERROR: Asset name suffix not specified."
        return 1
    fi

    >&2 echo "Selecting asset by suffix <${asset_name_suffix}>..."
    cat | \
        jq --raw-output --compact-output --monochrome-output --arg asset_name_suffix "${asset_name_suffix}" 'select(.name | endswith($asset_name_suffix))'
}

function github_select_asset_by_prefix() {
    local asset_name_prefix=$1

    if test -z "${asset_name_prefix}"; then
        echo "ERROR: Asset name prefix not specified."
        return 1
    fi

    >&2 echo "Selecting asset by prefix <${asset_name_prefix}>..."
    cat | \
        jq --raw-output --compact-output --monochrome-output --arg asset_name_prefix "${asset_name_prefix}" 'select(.name | startswith($asset_name_prefix))'
}

function github_get_asset_download_url() {
    >&2 echo "Fetching asset download URL..."
    cat | \
        jq --raw-output --compact-output --monochrome-output '.browser_download_url' | \
        tee >(cat | xargs -I{} echo "Downloading from <{}>" 1>&2)
}

function help_github_install() {
    echo "github_install <options>"
    echo
    echo "Options:"
    echo "    --name,     -n    Name of the binary to install"
    echo "    --repo,     -n    Repo to install the binary from"
    echo "    --type,     -t    Type of the asset of GitHub (binary, gunzip, tarball, zip, xz)"
    echo "    --include,  -i    List of files to include when unpacking type tarball or zip"
    echo "    --match,    -m    How to match the asset (name, prefix, suffix)"
    echo "    --asset,    -a    String to match the asset name"
    echo "    --help,     -h    This message"
    echo

    if test "$#" == 1; then
        exit "$1"
    fi
}

function github_install() {
    while test "$#" -gt 0; do
        local param=$1
        shift

        case "${param}" in
            --name|-n)
                local name=$1
            ;;
            --repo|-r)
                local repo=$1
            ;;
            --type|-t)
                local type=$1
            ;;
            --include|-i)
                local include=$1
            ;;
            --match|-m)
                local match=$1
            ;;
            --asset|-a)
                local asset=$1
            ;;
            --help|-h)
                help_github_install 0
            ;;
        esac

        shift
    done

    if test -z "${repo}"; then
        >&2 echo "ERROR: Parameter <repo> must not be empty."
        help_github_install 1
    fi
    if test -z "${type}"; then
        >&2 echo "ERROR: Parameter <type> must not be empty."
        help_github_install 1
    fi
    if test -z "${match}"; then
        >&2 echo "ERROR: Parameter <match> must not be empty."
        help_github_install 1
    fi
    if test -z "${asset}"; then
        >&2 echo "ERROR: Parameter <asset> must not be empty."
        help_github_install 1
    fi

    case "${type}" in
        binary|gunzip)
            test -n "${name}" || help_github_install 1
        ;;
        tarball|xz)
            test -n "${include}" || help_github_install 1
        ;;
        zip)
            test -n "${include}" || help_github_install 1
            tmpdir=$(mktemp -d)
            mkdir -p "${tmpdir}"
            >&2 echo "Using temporary directory <${tmpdir}>"
        ;;
        *)
            help_github_install 1
        ;;
    esac
    case "${match}" in
        name|prefix|suffix)
            :
        ;;
        *)
            help_github_install 1
        ;;
    esac

    github_get_release "${repo}" "${requested_version}" | \
        github_resolve_assets | \
        case "${match}" in
            name)
                github_select_asset_by_name "${asset}"
            ;;
            prefix)
                github_select_asset_by_prefix "${asset}"
            ;;
            suffix)
                github_select_asset_by_suffix "${asset}"
            ;;
        esac | \
        github_get_asset_download_url | \
        download_file | \
        case "${type}" in
            binary)
                store_file "${name}" | \
                make_executable
            ;;
            gunzip)
                gunzip_file | \
                store_file "${name}" | \
                make_executable
            ;;
            tarball)
                untar_file "${include}"
            ;;
            xz)
                unxz_file "${include}"
            ;;
            *)
                store_file "${name}.zip" "${tmpdir}"
                unzip_file "${tmpdir}/${name}.zip" "${include}"
            ;;
        esac

    case "${type}" in
        zip)
            rm -f "${tmpdir}/${name}.zip"
            rmdir "${tmpdir}"
        ;;
    esac
}