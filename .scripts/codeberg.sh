#!/bin/bash

function codeberg_api() {
    local project=$1
    local path=$2

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    CODEBERG_AUTH_PARAMETER=()
    if test -n "${CODEBERG_USER}" && test -n "${CODEBERG_TOKEN}"; then
        >&2 echo "Using authentication for GitHub"
        CODEBERG_AUTH_PARAMETER=("--user" "${CODEBERG_USER}:${CODEBERG_TOKEN}")
    fi

    curl "https://codeberg.org/api/v1/repos/${project}${path}" \
            "${CODEBERG_AUTH_PARAMETER[@]}" \
            --silent
}

function codeberg_get_repo_description() {
    local project=$1

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    >&2 echo "Fetching description for ${project}..."
    codeberg_api "${project}" "" | \
        jq --raw-output '.description'
}

function codeberg_get_releases() {
    local project=$1

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    >&2 echo "Fetching releases for ${project}..."
    codeberg_api "${project}" "/releases"
}

function codeberg_get_tags() {
    local project=$1

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    >&2 echo "Fetching tags for ${project}..."
    codeberg_api "${project}" "/tags"
}

function codeberg_find_latest_release() {
    local project=$1

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    >&2 echo "Fetching latest release for ${project}..."
    codeberg_get_releases "${project}" | \
        jq 'map(select(.prerelease == false)) | first' | \
        tee >(cat | jq --raw-output '.tag_name' | xargs -I{} echo "Installing version <{}>" 1>&2)
}

function codeberg_resolve_assets() {
    jq --raw-output --compact-output --monochrome-output '.assets[]'
}

function codeberg_select_asset_by_name() {
    local asset_name=$1

    if test -z "${asset_name}"; then
        echo "ERROR: Asset name not specified."
        return 1
    fi

    >&2 echo "Selecting asset by name <${asset_name}>..."
    cat | \
        jq --raw-output --compact-output --monochrome-output --arg asset_name "${asset_name}" 'select(.name == $asset_name)'
}

function codeberg_select_asset_by_suffix() {
    local asset_name_suffix=$1

    if test -z "${asset_name_suffix}"; then
        echo "ERROR: Asset name suffix not specified."
        return 1
    fi

    >&2 echo "Selecting asset by suffix <${asset_name_suffix}>..."
    cat | \
        jq --raw-output --compact-output --monochrome-output --arg asset_name_suffix "${asset_name_suffix}" 'select(.name | endswith($asset_name_suffix))'
}

function codeberg_select_asset_by_prefix() {
    local asset_name_prefix=$1

    if test -z "${asset_name_prefix}"; then
        echo "ERROR: Asset name prefix not specified."
        return 1
    fi

    >&2 echo "Selecting asset by prefix <${asset_name_prefix}>..."
    cat | \
        jq --raw-output --compact-output --monochrome-output --arg asset_name_prefix "${asset_name_prefix}" 'select(.name | startswith($asset_name_prefix))'
}

function codeberg_get_asset_download_url() {
    >&2 echo "Fetching asset download URL..."
    cat | \
        jq --raw-output --compact-output --monochrome-output '.browser_download_url' | \
        tee >(cat | xargs -I{} echo "Downloading from <{}>" 1>&2)
}

function codeberg_select_latest_tag {
    >&2 echo "Selecting latest tag..."
    cat | \
        jq --raw-output '.[].name' | sort -V | tail -n 1 | \
        tee >(cat | xargs -I{} echo "Selected tag <{}>" 1>&2)
}

function help_codeberg_install() {
    echo "codeberg_install <options>"
    echo
    echo "Options:"
    echo "    --name,     -n    Name of the binary to install"
    echo "    --repo,     -n    Repo to install the binary from"
    echo "    --type,     -t    Type of the asset of Codeberg (binary, gunzip, tarball, zip, xz)"
    echo "    --include,  -i    List of files to include when unpacking type tarball or zip"
    echo "    --match,    -m    How to match the asset (name, prefix, suffix)"
    echo "    --asset,    -a    String to match the asset name"
    echo "    --help,     -h    This message"
    echo

    if test "$#" == 1; then
        exit "$1"
    fi
}

function codeberg_install() {
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
                help_codeberg_install 0
            ;;
        esac

        shift
    done

    if test -z "${repo}"; then
        >&2 echo "ERROR: Parameter <repo> must not be empty."
        help_codeberg_install 1
    fi
    if test -z "${type}"; then
        >&2 echo "ERROR: Parameter <type> must not be empty."
        help_codeberg_install 1
    fi
    if test -z "${match}"; then
        >&2 echo "ERROR: Parameter <match> must not be empty."
        help_codeberg_install 1
    fi
    if test -z "${asset}"; then
        >&2 echo "ERROR: Parameter <asset> must not be empty."
        help_codeberg_install 1
    fi

    case "${type}" in
        binary|gunzip)
            test -n "${name}" || help_codeberg_install 1
        ;;
        tarball|xz)
            test -n "${include}" || help_codeberg_install 1
        ;;
        zip)
            test -n "${include}" || help_codeberg_install 1
            tmpdir=$(mktemp -d)
            mkdir -p "${tmpdir}"
            >&2 echo "Using temporary directory <${tmpdir}>"
        ;;
        *)
            help_codeberg_install 1
        ;;
    esac
    case "${match}" in
        name|prefix|suffix)
            :
        ;;
        *)
            help_codeberg_install 1
        ;;
    esac

    codeberg_find_latest_release "${repo}" | \
        codeberg_resolve_assets | \
        case "${match}" in
            name)
                codeberg_select_asset_by_name "${asset}"
            ;;
            prefix)
                codeberg_select_asset_by_prefix "${asset}"
            ;;
            suffix)
                codeberg_select_asset_by_suffix "${asset}"
            ;;
        esac | \
        codeberg_get_asset_download_url | \
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