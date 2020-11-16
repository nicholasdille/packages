#!/bin/bash

set -o errexit

MY_REPO=nicholasdille/packages
MY_VERSION=master

: "${TARGET_BASE:=/usr/local}"
: "${TARGET_BIN:=${TARGET_BASE}/bin}"
: "${TARGET_COMPLETION:=${TARGET_BASE}/etc/bash_completion.d}"

: "${CURL_DOWNLOAD_SILENT:=false}"
: "${TAR_VERBOSE:=false}"
: "${ZIP_VERBOSE:=false}"

export DOCKER_BUILDKIT=1

container_name=$(basename "$(mktemp --dry-run)")

cleanup_tasks=()

function cleanup() {
    for cleanup_task in "${cleanup_tasks[@]}"; do
        ${cleanup_task}
    done
}
trap cleanup EXIT

function remove_temporary_container() {
    #echo "Cleaning up temporary container..."
    if type docker >/dev/null 2>&1 && docker version >/dev/null 2>&1; then
        docker ps --all --quiet --filter name="${container_name}" | xargs --no-run-if-empty docker rm
    fi
}

function remove_temporary_directory() {
    if test -n "${temporary_directory}" && test -d "${temporary_directory}"; then
        rm -rf "${temporary_directory:?}"
    fi
}
function check_target() {
    >&2 echo "Checking existence of target directory <${TARGET_BASE}>"
    if ! test -d "${TARGET_BASE}"; then
        >&2 echo "ERROR: Target directory <${TARGET_BASE}> does not exist. Please create it first."
        exit 1
    fi
}

function create_target() {
    ${SUDO} mkdir -p "${TARGET_BIN}"
    ${SUDO} mkdir -p "${TARGET_COMPLETION}"
}

function target_requires_sudo() {
    check_target

    # target directory is root-owned
    if test "$(stat "${TARGET_BASE}" -c '%u:%g')" == "0:0"; then

        # we are not root right now
        if test "$(id -u)" != "0"; then
            >&2 echo "Target directory requires root access."
            export SUDO="sudo"
            export NODE_PARAMS=("-g")
            return 0
        fi
    fi

    # otherwise no sudo is required
    return 1
}

function sudo_requires_password() {
    if ! sudo -n true 2>&1; then
        >&2 echo "Sudo requires a password"
        return 0
    fi
    return 1
}

function unlock_sudo() {
    if target_requires_sudo; then
        if sudo_requires_password; then
            >&2 echo "Please enter your password to unlock sudo for the installation."
            sudo true
        else
            >&2 echo "Sudo does not require a password (this time)."
        fi
    fi

    create_target
}

function download_file() {
    if ${CURL_DOWNLOAD_SILENT}; then
        CURL_ADDITIONAL_PARAMS="--silent"
    fi

    >&2 echo "Downloading file..."
    cat | \
        xargs curl --location --fail ${CURL_ADDITIONAL_PARAMS}
}

function untar_file() {
    local parameters=("$@")

    if ${TAR_VERBOSE}; then
        TAR_ADDITIONAL_PARAMS="-v"
    fi

    >&2 echo "Unpacking asset to directory ${TARGET_BIN}..."
    >&2 echo "  Including parameters <${parameters[*]}>"
    cat | \
        ${SUDO} tar -x -z ${TAR_ADDITIONAL_PARAMS} -C "${TARGET_BIN}" "${parameters[@]}"
}

function unxz_file() {
    local parameters=("$@")

    if ${TAR_VERBOSE}; then
        TAR_ADDITIONAL_PARAMS="-v"
    fi

    >&2 echo "Unpacking asset to directory ${TARGET_BIN}..."
    >&2 echo "  Including parameters <${parameters[*]}>"
    cat | \
        ${SUDO} tar -x -J ${TAR_ADDITIONAL_PARAMS} -C "${TARGET_BIN}" "${parameters[@]}"
}

function unzip_file {
    local file=$1
    shift
    local filter=("$@")

    ZIP_ADDITIONAL_PARAMS="-q"
    if ${TAR_VERBOSE}; then
        ZIP_ADDITIONAL_PARAMS="-v"
    fi

    ${SUDO} unzip -o ${ZIP_ADDITIONAL_PARAMS} -d "${TARGET_BIN}" "${file}" "${filter[@]}"
}

function gunzip_file() {
    cat | \
        gunzip
}

function store_file() {
    local filename=$1
    local dirname=$2

    if test -z "${filename}"; then
        echo "ERROR: File name not specified."
        return 1
    fi

    if test -z "${dirname}"; then
        dirname="${TARGET_BIN}"
    fi

    >&2 echo "Creating file ${dirname}/${filename}"
    cat | \
        ${SUDO} tee "${dirname}/${filename}" >/dev/null
    echo "${dirname}/${filename}"
}

function make_executable() {
    local filename=$1

    if test -z "${filename}"; then
        cat | while read -r filename2; do
            >&2 echo "Setting executable bits on ${filename2}"
            ${SUDO} chmod +x "${filename2}"
        done
        return
    fi

    >&2 echo "Setting executable bits on ${filename}"
    ${SUDO} chmod +x "${TARGET_BIN}/${filename}"
}

function rename_file() {
    local old_name=$1
    local new_name=$2

    if test -z "${old_name}"; then
        echo "ERROR: Name of existing file not specified."
        exit 1
    fi
    if test -z "${new_name}"; then
        echo "ERROR: New name of file not specified."
        exit 1
    fi

    >&2 echo "Renaming ${old_name} to ${new_name}..."
    ${SUDO} mv "${TARGET_BIN}/${old_name}" "${TARGET_BIN}/${new_name}"
}

function store_completion() {
    local filename=$1

    if test -z "${filename}"; then
        echo "ERROR: File name not specified."
        return 1
    fi

    ${SUDO} mkdir -p "${TARGET_COMPLETION}"

    cat | \
        store_file "${filename}.sh" "${TARGET_COMPLETION}"
    if test -n "${SUDO}"; then
        ${SUDO} ln -sf "${TARGET_COMPLETION}/${filename}.sh" /etc/bash_completion.d/
    else
        >&2 echo "!!! Please make sure the completion if loaded from <${TARGET_COMPLETION}/${filename}.sh>"
    fi
}

function install_node_module() {
    require node
    ${SUDO} npm install "${NODE_PARAMS[@]}" "$@"
}

function install_python_module() {
    require python
    ${SUDO} bash --login -c "pip3 install --upgrade $*"
}

function install_ruby_module() {
    require ruby
    ${SUDO} bash --login -c "gem install $*"
}

function get_package_definition() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    # shellcheck disable=SC2154
    if test -f "${working_directory}/${package}/package.yaml"; then
        >&2 echo "Using local package.yaml"
        yq --tojson read "${working_directory}/${package}/package.yaml"

    else
        get_packages | \
            jq --arg package "${package}" '.packages[] | select(.name == $package)'
    fi
}

function get_installed_version() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    local PACKAGE_JSON
    PACKAGE_JSON=$(get_package_definition "${package}")

    local version_command
    version_command=$(
        echo "${PACKAGE_JSON}" | \
            jq --raw-output .version.command
    )
    if test -z "${version_command}" || test "${version_command}" == "null"; then
        >&2 echo "WARNING: No version command specified for package <${package}>."
        return
    fi

    local version_filter
    version_filter=$(
        echo "${PACKAGE_JSON}" | \
            jq --raw-output '.version.filter'
    )
    if test -z "${version_filter}" || test "${version_filter}" == "null"; then
        >&2 echo "WARNING: No version filter specified for package <${package}>."
        return
    fi

    local version_pattern
    version_pattern=$(
        echo "${PACKAGE_JSON}" | \
            jq --raw-output '.version.pattern'
    )
    if test -z "${version_pattern}" || test "${version_pattern}" == "null"; then
        >&2 echo "WARNING: No version pattern specified for package <${package}>."
        return
    fi

    # shellcheck disable=SC2086
    ${TARGET_BIN}/${version_command} 2>/dev/null | \
        grep "${version_filter}" | \
        sed -E "${version_pattern}"
}

function get_latest_version() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    local PACKAGE_JSON
    PACKAGE_JSON=$(get_package_definition "${package}")

    echo "${PACKAGE_JSON}" | \
        jq --raw-output '.version.latest'
}

function latest_version_installed() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    local installed_version
    installed_version=$(get_installed_version "${package}")
    if test -z "${installed_version}"; then
        echo "WARNING: Unable to determine installed version."
        return 1
    fi

    local latest_version
    latest_version=$(get_latest_version "${package}")
    if test -z "${latest_version}"; then
        echo "WARNING: Unable to determine latest version."
        return 1
    fi

    >&2 echo "Comparing installed version ${installed_version} with latest version ${latest_version}..."
    if test "${installed_version}" == "${latest_version}"; then
        return 0
    else
        return 1
    fi
}

function check_installed_version() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    if latest_version_installed "${package}"; then
        echo "Latest version of ${package} is already installed."
        exit
    fi
}

function get_file() {
    local package=$1
    if test -z "${package}"; then
        >&2 echo "ERROR: No package specified."
        exit 1
    fi

    local file=$2
    if test -z "${file}"; then
        >&2 echo "ERROR: No file specified."
        exit 1
    fi

    get_package_definition "${package}" | \
        jq \
            --raw-output \
            --arg file "${file}" \
            '.files[] | select(.name == $file) | .content'
}

function get_install_script() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    get_package_definition "${package}" | \
        jq \
            --raw-output \
            '.install.script'
}

function package_needs_docker() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    local needs_docker
    needs_docker=$(
        get_package_definition "${package}" | \
            jq \
                --raw-output \
                '.install.docker'
        )
    
    case "${needs_docker}" in
        true|yes|1)
            return 0
        ;;
        *)
            return 1
        ;;
    esac
}

function require() {
    local package=$1

    if test -z "${package}"; then
        echo "ERROR: Package must be supplied."
        exit 1
    fi

    echo
    echo "### Installing dependency <${package}>..."
    curl --silent "https://pkg.dille.io/pkg.sh" | \
        bash -s install "${package}"
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

function github_api() {
    local path=$1

    GITHUB_AUTH_PARAMETER=()
    if test -n "${GITHUB_USER}" && test -n "${GITHUB_TOKEN}"; then
        >&2 echo "Using authentication for GitHub"
        GITHUB_AUTH_PARAMETER=("--user" "${GITHUB_USER}:${GITHUB_TOKEN}")
    fi

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

    # shellcheck disable=SC2154
    cat | \
        docker run -i --name "${container_name}" --env requested_version="${requested_version}" "${image}" "${command[@]}"
}

function extract_file_from_container() {
    while test -n "$1"; do
        docker cp "${container_name}:/$1" - | ${SUDO} tar -xvC "${TARGET_BIN}"
        shift
    done
}

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

    if ! test -f "${HOME}/.pkg/packages.json"; then
        handle_cache
    fi

    for package_spec in "$@"; do
        local package
        package=$(echo "${package_spec}" | cut -d@ -f1)
        local requested_version
        requested_version=$(echo "${package_spec}" | cut -d@ -f2)
        if test "${requested_version}" == "${package}"; then
            unset requested_version
        fi

        local package_definition
        package_definition=$(get_package_definition "${package}")
        if test -z "${package_definition}"; then
            echo "ERROR: Package ${package} not found"
            exit 1
        fi

        working_directory="${PWD}"

        temporary_directory=$(mktemp -d)
        # shellcheck disable=SC2164
        cd "${temporary_directory}"
        cleanup_tasks+=("remove_temporary_directory")

        check_installed_version "${package}"
        if package_needs_docker "${package}"; then
            check_docker
            cleanup_tasks+=("remove_temporary_container")
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
    : "${VERSION:=latest}"
    if test -z "${TAG}"; then
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
