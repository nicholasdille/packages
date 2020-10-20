#!/bin/bash

function github_api() {
    local project=$1
    local path=$2
    local file=$3

    if test -z "${project}"; then
        error "Project not specified."
        return 1
    fi
    if test -z "${file}"; then
        error "Output file not specified."
        return 1
    fi

    GITHUB_AUTH_PARAMETER=()
    if test -n "${GITHUB_USER}" && test -n "${GITHUB_TOKEN}"; then
        log VERBOSE "Using authentication for GitHub"
        GITHUB_AUTH_PARAMETER=("--user" "${GITHUB_USER}:${GITHUB_TOKEN}")
    else
        warning "Not using authentication for GitHub!"
    fi

    log VERBOSE "Calling GitHub API for project <${project}> on path <${path}>"
    curl "https://api.github.com/repos/${project}${path}" \
            "${GITHUB_AUTH_PARAMETER[@]}" \
            --silent \
        >"${file}"
}

function github_get_repo_description() {
    local project=$1

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    >&2 echo "Fetching description for ${project}..."
    github_api "${project}" "" | \
        jq --raw-output '.description'
}

function github_get_releases() {
    local project=$1

    if test -z "${project}"; then
        error "Project not specified."
        return 1
    fi

    log VERBOSE "Fetching releases for ${project}..."
    github_api "${project}" "/releases" "${PACKAGES_TEMP_DIR}/github_releases.json"
}

function github_find_latest_release() {
    local project=$1

    if test -z "${project}"; then
        error "Project not specified."
        return 1
    fi

    log VERBOSE "Fetching latest release for ${project}..."
    github_api "${project}" "/releases/latest" "${PACKAGES_TEMP_DIR}/github_selected_release.json"
    jq --raw-output '.tag_name' "${PACKAGES_TEMP_DIR}/github_selected_release.json" >"${PACKAGES_TEMP_DIR}/github_selected_release.txt"

    export GITHUB_RELEASE_TAG
    GITHUB_RELEASE_TAG=$(cat "${PACKAGES_TEMP_DIR}/github_selected_release.txt")
    log INFO "Installing version <${GITHUB_RELEASE_TAG}>"
}

function github_resolve_assets() {
    log VERBOSE "Resolving assets..."
    jq \
        --raw-output \
        --compact-output \
        --monochrome-output \
        '.assets[]' \
        "${PACKAGES_TEMP_DIR}/github_selected_release.json" \
        >"${PACKAGES_TEMP_DIR}/github_selected_release_assets.json"
}

function github_select_asset_by_name() {
    local asset_name=$1

    if test -z "${asset_name}"; then
        echo "ERROR: Asset name not specified."
        return 1
    fi

    if ! test -f "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json"; then
        log VERBOSE "This is the first filter to run."
        cp \
            "${PACKAGES_TEMP_DIR}/github_selected_release_assets.json" \
            "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json"
    fi

    log VERBOSE "Selecting asset by suffix <${asset_name_suffix}>..."
    mv \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json" \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset_last.json"
    jq \
        --raw-output \
        --compact-output \
        --monochrome-output \
        --arg asset_name_suffix "${asset_name_suffix}" \
        'select(.name == $asset_name)' \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset_last.json" \
        >"${PACKAGES_TEMP_DIR}/github_selected_release_asset.json"
    rm "${PACKAGES_TEMP_DIR}/github_selected_release_asset_last.json"
}

function github_select_asset_by_suffix() {
    local asset_name_suffix=$1

    if test -z "${asset_name_suffix}"; then
        error "Asset name suffix not specified."
        return 1
    fi

    if ! test -f "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json"; then
        log VERBOSE "This is the first filter to run."
        cp \
            "${PACKAGES_TEMP_DIR}/github_selected_release_assets.json" \
            "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json"
    fi

    log VERBOSE "Selecting asset by suffix <${asset_name_suffix}>..."
    mv \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json" \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset_last.json"
    jq \
        --raw-output \
        --compact-output \
        --monochrome-output \
        --arg asset_name_suffix "${asset_name_suffix}" \
        'select(.name | endswith($asset_name_suffix))' \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset_last.json" \
        >"${PACKAGES_TEMP_DIR}/github_selected_release_asset.json"
    rm "${PACKAGES_TEMP_DIR}/github_selected_release_asset_last.json"
}

function github_select_asset_by_prefix() {
    local asset_name_prefix=$1

    if test -z "${asset_name_prefix}"; then
        error "Asset name prefix not specified."
        return 1
    fi

    if ! test -f "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json"; then
        log VERBOSE "This is the first filter to run."
        cp \
            "${PACKAGES_TEMP_DIR}/github_selected_release_assets.json" \
            "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json"
    fi

    log VERBOSE "Selecting asset by prefix <${asset_name_prefix}>..."
    mv \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json" \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset_last.json"
    jq \
        --raw-output \
        --compact-output \
        --monochrome-output \
        --arg asset_name_prefix "${asset_name_prefix}" \
        'select(.name | startswith($asset_name_prefix))' \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset_last.json" \
        >"${PACKAGES_TEMP_DIR}/github_selected_release_asset.json"
    rm "${PACKAGES_TEMP_DIR}/github_selected_release_asset_last.json"
}

function github_get_asset_download_url() {
    if ! test -f "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json"; then
        error "No asset was selected. Call <github_select_asset_by_{name,prefix,suffix}>."
        exit 1
    fi
    log INFO "Fetching asset download URL..."
    jq \
        --raw-output \
        --compact-output \
        --monochrome-output \
        '.browser_download_url' \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset.json" \
        >"${PACKAGES_TEMP_DIR}/github_selected_release_asset.txt"
    log VERBOSE "Downloading from <$(cat "${PACKAGES_TEMP_DIR}/github_selected_release_asset.txt")>"
}

function github_download_file() {
    if ! test -f "${PACKAGES_TEMP_DIR}/github_selected_release_asset.txt"; then
        error "Download URL for release asset not found."
        exit 1
    fi

    log VERBOSE "Preparing download of file from GitHub."
    mv \
        "${PACKAGES_TEMP_DIR}/github_selected_release_asset.txt" \
        "${PACKAGES_TEMP_DIR}/download_file.txt"
    download_file
}

function github_get_tags() {
    local project=$1

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    log INFO "Fetching tags for ${project}..."
    github_api "${project}" "/git/matching-refs/tags" "${PACKAGES_TEMP_DIR}/github_tags.json"
}

function github_select_latest_tag {
    log INFO "Selecting latest tag..."
    jq \
            --raw-output \
            '.[].ref' \
            "${PACKAGES_TEMP_DIR}/github_tags.json" | \
        cut -d/ -f3 | \
        sort -V | \
        tail -n 1 \
    >"${PACKAGES_TEMP_DIR}/github_selected_tag.txt"
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

    github_find_latest_release "${repo}" | \
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