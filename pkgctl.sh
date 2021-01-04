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

function download() {
    local url=$1
    if test -z "${url}"; then
        echo "ERROR: URL must be specified."
        exit 1
    fi
    >&2 echo "Downloading file from <${url}>..."
    curl --location --fail --remote-name "${url}"
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

function unpack() {
    local filename=$1
    if test -z "${filename}"; then
        echo "ERROR: Filename must be specified."
        exit 1
    fi
    shift
    if ! test -s "${temporary_directory}/${filename}"; then
        echo "ERROR: Filename must exist."
        exit 1
    fi
    local parameters=("$@")

    : "${COMPRESSION_PARAMETER:=-z}"

    >&2 echo "Unpacking asset to temporary directory..."
    if test "${#parameters[*]}" -gt 0; then
        >&2 echo "  Including parameters <${parameters[*]}>"
    fi
    tar -x "${COMPRESSION_PARAMETER}" -C "${temporary_directory}" -f "${temporary_directory}/${filename}" "${parameters[@]}"
}

function untargz() {
    COMPRESSION_PARAMETER="-z" unpack "$@"
}

function untarxz() {
    COMPRESSION_PARAMETER="-J" unpack "$@"
}

function untarbz2() {
    COMPRESSION_PARAMETER="-j" unpack "$@"
}

function ungz() {
    local filename=$1
    if test -z "${filename}"; then
        echo "ERROR: Filename must be specified."
        exit 1
    fi
    shift
    if ! test -s "${temporary_directory}/${filename}"; then
        echo "ERROR: Filename must exist."
        exit 1
    fi

    >&2 echo "Unpacking asset in temporary directory..."
    gunzip "${temporary_directory}/${filename}"
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

function install_file() {
    local filename=$1
    if test -z "${filename}"; then
        echo "ERROR: Filename must be specified."
        exit 1
    fi
    shift
    local mode=$1
    if test -z "${mode}"; then
        mode=0644
    fi

    if test -z "${TARGET}"; then
        echo "ERROR: Target must not be empty."
        exit 1
    fi

    local FILES=""
    if test -d "${temporary_directory}/${filename}"; then
        >&2 echo "DEBUG: Filename points to a directory."
        FILES="$(find "${temporary_directory}/${filename}" -maxdepth 1 -type f -executable)"

    elif test -s "${temporary_directory}/${filename}"; then
        >&2 echo "DEBUG: Filename points to a non-empty file."
        FILES="${temporary_directory}/${filename}"

    else
        echo "ERROR: Unable to determine type of <${filename}> (neither file nor directory)."
        exit 1
    fi

    ${SUDO} install --directory "${TARGET}"
    for binary in ${FILES}; do
        ${SUDO} install --verbose --mode="${mode}" --compare "${binary}" "${TARGET}"
    done
}

function install_binary() {
    : "${TARGET:=${TARGET_BIN}}"
    TARGET="${TARGET}" install_file "$1" "0755"
}

function install_completion() {
    TARGET="${TARGET_COMPLETION}" install_binary "$1" "0644"
}

function install_manpage() {
    local man=$1
    TARGET="${TARGET_BASE}/share/man/man${man}" install_file "$2" "0644"
}

# shellcheck disable=SC2120
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
    ${SUDO} pip3 install --upgrade "$@"
}

function install_ruby_module() {
    require ruby
    ${SUDO} gem install "$@"
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

        if test "$(yq --version | sed -E "s/^yq\sversion\s([0-9]+)\..+$/\1/")" == "3"; then
            yq --tojson read "${working_directory}/${package}/package.yaml"

        elif test "$(yq --version | sed -E "s/^yq\sversion\s([0-9]+)\..+$/\1/")" == "4"; then
            yq --tojson eval '.' "${working_directory}/${package}/package.yaml"

        else
            echo "ERROR: Unable to determine version of yq."
            exit 1
        fi

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

    PACKAGE_JSON=$(cat "${temporary_directory}/package.json")

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
    eval "${version_command} | \
        grep \"${version_filter}\" | \
        sed -E \"${version_pattern}\"" 2>/dev/null
}

function get_latest_version() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    cat "${temporary_directory}/package.json" | \
        jq --raw-output '.version.latest'
}

function requested_version_installed() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi
    local requested_version=$2

    local installed_version
    installed_version=$(get_installed_version "${package}")
    if test -z "${installed_version}"; then
        echo "WARNING: Unable to determine installed version."
        return 1
    fi

    if test -z "${requested_version}"; then
        requested_version=$(get_latest_version "${package}")
        if test -z "${requested_version}"; then
            echo "WARNING: Unable to determine latest version."
            return 1
        fi
    fi

    >&2 echo "Comparing installed version ${installed_version} with version ${requested_version}..."
    if test "${installed_version}" == "${requested_version}"; then
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
    local requested_version=$2

    if requested_version_installed "${package}" "${requested_version}"; then
        echo "Latest version of ${package} is already installed."
        exit
    fi
}

function get_install_script() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    cat "${temporary_directory}/package.json" | \
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
        cat "${temporary_directory}/package.json" | \
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
    force_install=false force_install_recursive=${force_install_recursive} install_package "${package}"
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

function github_api() {
    local path=$1

    GITHUB_AUTH_PARAMETER=()
    if test -n "${GITHUB_TOKEN}"; then
        >&2 echo "Using authentication for GitHub"
        GITHUB_AUTH_PARAMETER=("--header" "Authorization: token ${GITHUB_TOKEN}")
    else
        if ! github_rate_limit_ok; then
            echo "ERROR: Rate limit exceeded"
            exit 1
        fi
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
        curl --silent "https://api.github.com/rate_limit" | \
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

function github_get_releases() {
    local project=$1

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    >&2 echo "Fetching releases for ${project}..."
    github_api_repo "${project}" "/releases"
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

function show_help() {
    echo
    echo "Usage: sh ./pkgctl.sh <command>"
    echo "       ./pkgctl.sh <command>"
    echo "       curl https://pkg.dille.io/pkgctl.sh | sh -s <command>"
    echo
    echo "Commands:"
    echo "    bootstrap, c   Bootstrap pkgctl.sh"
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

function show_help_bootstrap() {
    echo
    echo "Usage: sh ./pkgctl.sh bootstrap [--prefix \${HOME}/.local] <string>"
    echo "       ./pkgctl.sh bootstrap [--prefix \${HOME}/.local] <string>"
    echo "       curl https://pkg.dille.io/pkgctl.sh | sh -s bootstrap [<options>] <string>"
    echo
    echo "Options:"
    echo "    --prefix    Location to install pkgctl into (defaults to \${HOME}/.local)"
    echo
}

function show_help_install() {
    echo
    echo "Usage: sh ./pkgctl.sh install <package>[,<package>]"
    echo "       ./pkgctl.sh install <package>[,<package>]"
    echo "       curl https://pkg.dille.io/pkgctl.sh | sh -s install [<options>] <package>[,<package>]"
    echo
    echo "Options:"
    echo "    --force, -f    Force installation of specified package"
    echo "    --force-all    Force installation of specified package as well as all dependencies"
    echo
}

function show_help_file() {
    echo
    echo "Usage: sh ./pkgctl.sh file <package> [<file>]"
    echo "       ./pkgctl.sh file <package> [<file>]"
    echo "       curl https://pkg.dille.io/pkgctl.sh | sh -s file <package> [<>]"
    echo
}

function show_help_search() {
    echo
    echo "Usage: sh ./pkgctl.sh search <string>"
    echo "       ./pkgctl.sh search <string>"
    echo "       curl https://pkg.dille.io/pkgctl.sh | sh -s search [<options>] <string>"
    echo
    echo "Options:"
    echo "    --name, -n    Only search in package name"
    echo "    --desc, -d    Only search in package description"
    echo "    --tags, -t    Only search in package tags"
    echo
}

function show_help_version() {
    echo
    echo "Usage: sh ./pkgctl.sh version <package>"
    echo "       ./pkgctl.sh version <package>"
    echo "       curl https://pkg.dille.io/pkgctl.sh | sh -s version <package>"
    echo
}

function get_packages() {
    if test -f "${HOME}/.pkgctl/packages.json"; then
        cat "${HOME}/.pkgctl/packages.json"

    elif test -f packages.json; then
        >&2 echo "Using local copy of packages.json in current directory. If you are not a contributor, please run <pkg cache>."
        cat packages.json

    else
        >&2 echo "ERROR: Unable to find packages.json. Run <pkg cache> first."
        exit 1
    fi
}

function handle_bootstrap() {
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
    curl --silent --location "https://raw.githubusercontent.com/${MY_REPO}/${MY_VERSION}/pkgctl.sh" \
        >"${PREFIX}/bin/pkgctl"
    chmod +x "${PREFIX}/bin/pkgctl"
}

function handle_cache() {
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

    mkdir -p "${HOME}/.pkgctl"
    echo "Using version ${TAG}."
    curl --silent "https://api.github.com/repos/${MY_REPO}/releases/tags/${TAG}" | \
        jq --raw-output '.assets[] | select(.name == "packages.json") | .browser_download_url' | \
        xargs curl --silent --location --output "${HOME}/.pkgctl/packages.json"
}

function handle_file() {
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
        get_packages | \
            jq --raw-output --arg package "${package}" --arg file "${file}" '
                .packages[] |
                select(.name == $package) |
                .files[] |
                select(.name == $file) |
                .content
            '
    fi
}

function handle_inspect() {
    package=$1

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        show_help_install
        exit 1
    fi

    get_packages | \
        jq --arg package "${package}" '.packages[] | select(.name == $package)'
}

function install_package() {
    local package=$1
    if test -z "${package}"; then
        echo "ERROR: Package name must be specified."
        exit 1
    fi
    local requested_version=$2

    export PACKAGE_NAME=${package}

    temporary_directory=$(mktemp -d)
    # shellcheck disable=SC2164
    cd "${temporary_directory}"
    cleanup_tasks+=("remove_temporary_directory")

    get_package_definition "${package}" >"${temporary_directory}/package.json"
    PACKAGE_REPOSITORY="$(jq --raw-output .repo "${temporary_directory}/package.json")"
    export PACKAGE_REPOSITORY

    latest_version=$(get_latest_version "${package}")
    if test "${latest_version}" == "null"; then
        latest_version=""
    fi
    if test -z "${requested_version}"; then
        requested_version="${latest_version}"
    fi
    export PACKAGE_LATEST_VERSION="${latest_version}"
    export PACKAGE_REQUESTED_VERSION="${requested_version}"

    if ${force_install} || ${force_install_recursive}; then
        echo "WARNING: This is a forced installation."
    else
        if requested_version_installed "${package}" "${requested_version}"; then
            echo "Requested version ${requested_version} of ${package} is already installed."
            return
        fi
    fi

    if package_needs_docker "${package}"; then
        check_docker
        cleanup_tasks+=("remove_temporary_container")
    fi
    unlock_sudo

    for filename in $(jq --raw-output 'select(.files != null) | .files[].name' "${temporary_directory}/package.json"); do
        jq --raw-output --arg name "${filename}" '.files[] | select(.name == $name) | .content' "${temporary_directory}/package.json" >"${temporary_directory}/${filename}"
    done

    install_script="$(get_install_script "${package}")"
    if test -z "${requested_version}"; then
        if echo "${install_script}" | grep requested_version; then
            echo "ERROR: Requested package version is empty but install script uses it."
            exit 1
        fi
    fi

    echo "Installing ${package} version ${requested_version:-UNKNOWN}..."

    eval "${install_script}"

    echo "Finished installation of ${package} version ${requested_version:-UNKNOWN}."
}

function handle_install() {
    local force_install=false
    local force_install_recursive=false
    local file=""
    while test "$#" -gt 0; do
        case "$1" in
            --force|-f)
                force_install=true
                ;;
            --force-all)
                force_install=true
                force_install_recursive=true
                ;;
            --file)
                shift
                file=$1
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    if test -n "${file}"; then
        if ! test -s "${file}"; then
            echo "ERROR: File does not exist."
            exit 1
        fi
        # shellcheck disable=SC2046
        set -- $(cat "${file}") "$@"
    fi

    if test "$#" -eq 0; then
        echo "ERROR: No package specified."
        show_help_install
        exit 1
    fi

    if ! test -f "${HOME}/.pkgctl/packages.json"; then
        handle_cache
    fi

    working_directory="${PWD}"

    for package_spec in "$@"; do
        local package
        package=$(echo "${package_spec}" | cut -d@ -f1)
        local requested_version
        requested_version=$(echo "${package_spec}" | cut -d@ -f2)
        if test "${requested_version}" == "${package}"; then
            unset requested_version
        fi

        force_install=${force_install} force_install_recursive=${force_install_recursive} install_package "${package}" "${requested_version}"
    done
}

function handle_list() {
    get_packages | \
        jq --raw-output '
            .packages[] |
            "\(.name);\(.description)"
        ' | \
        uniq | \
        sort | \
        column -t -s ';'
}

function handle_search() {
    SEARCH_TERM=""
    SEARCH_NAME=false
    SEARCH_DESC=false
    SEARCH_TAGS=false
    while test "$#" -gt 0; do
        case "$1" in
            --name|-n)
                SEARCH_NAME=true
            ;;
            --desc|-d)
                SEARCH_DESC=true
            ;;
            --tags|-t)
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

function handle_tags() {
    get_packages | \
        jq --raw-output '.packages[].tags[]' | \
        sort | \
        uniq
}

function handle_version() {
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

    eval "${version_command} | \
        grep \"${version_filter}\" | \
        sed -E \"${version_pattern}\""
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
                echo "pkgctl version ${MY_VERSION}"
                exit 0
            ;;
            cache|c)
                handle_cache "$@"
                exit 0
            ;;
            bootstrap|b)
                handle_bootstrap "$@"
                exit 0
            ;;
            file|f)
                handle_file "$@"
                exit 0
            ;;
            inspect)
                handle_inspect "$@"
                exit 0
            ;;
            install|i)
                handle_install "$@"
                exit 0
            ;;
            list|l)
                handle_list "$@"
                exit 0
            ;;
            search|s)
                handle_search "$@"
                exit 0
            ;;
            tags|t)
                handle_tags "$@"
                exit 0
            ;;
            version|v)
                handle_version "$@"
                exit 0
            ;;
        esac
        shift
    done
}

case "$0" in
    -bash)
        # Was started using "source pkgctl.sh"
        echo "ERROR: Do not source this script."
    ;;
    bash)
        # Was started using "bash pkgctl.sh"
        main "$@"
    ;;
    *)
        # Was started using "./pkgctl.sh"
        main "$@"
    ;;
esac

set +o errexit
