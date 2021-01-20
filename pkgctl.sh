#!/bin/bash

set -o errexit

# shellcheck disable=SC2034
DEFAULT="\e[39m\e[49m"
# shellcheck disable=SC2034
LIGHT_GRAY="\e[37m"

# shellcheck disable=SC2034
DARK_GRAY="\e[90m"
# shellcheck disable=SC2034
RED="\e[91m"
# shellcheck disable=SC2034
GREEN="\e[92m"
# shellcheck disable=SC2034
YELLOW="\e[93m"
# shellcheck disable=SC2034
BLUE="\e[94m"
# shellcheck disable=SC2034
MAGENTA="\e[95m"
# shellcheck disable=SC2034
CYAN="\e[96m"

# shellcheck disable=SC2034
BG_DARKGRAY="\e[100m"
# shellcheck disable=SC2034
BG_RED="\e[101m"
# shellcheck disable=SC2034
BG_GREEN="\e[102m"
# shellcheck disable=SC2034
BG_YELLOW="\e[103m"
# shellcheck disable=SC2034
BG_BLUE="\e[104m"
# shellcheck disable=SC2034
BG_MAGENTA="\e[105m"
# shellcheck disable=SC2034
BG_CYAN="\e[106m"

function echo_color() {
    local color=$1
    local message=$2

    echo -e "${!color}${message}${DEFAULT}"
}

function echo_stderr_color() {
    local color=$1
    local message=$2

    >&2 echo -e "${!color}${message}${DEFAULT}"
}

declare -a LOG_LEVELS
LOG_LEVELS=(
    "SILENT"
    "QUIET"
    "INFO"
    "VERBOSE"
    "DEBUG"
)

declare -A LOG_LEVEL_COLORS
LOG_LEVEL_COLORS[SILENT]=DEFAULT
LOG_LEVEL_COLORS[QUIET]=DEFAULT
LOG_LEVEL_COLORS[INFO]=DEFAULT
LOG_LEVEL_COLORS[VERBOSE]=GREEN
LOG_LEVEL_COLORS[DEBUG]=YELLOW

function get_log_level_id() {
    local level=$1

    for index in $(seq 0 1 $(( ${#LOG_LEVELS[@]} - 1 ))); do
        if test "${LOG_LEVELS[${index}]}" == "${level^^}"; then
            echo ${index}
            break
        fi
    done
}

LOG_LEVEL=INFO
LOG_LEVEL_ID=$(get_log_level_id "${LOG_LEVEL}")

function log() {
    local level=$1
    local message=$2

    local level_id
    level_id="$(get_log_level_id "${level}")"
    if test "${level_id}" -le ${LOG_LEVEL_ID}; then
        local color="${LOG_LEVEL_COLORS[${level}]}"
        echo_color "${color}" "${message}"
    fi
}

function silent() {
    log SILENT "$@"
}

function quiet() {
    log QUIET "$@"
}

function info() {
    log INFO "$@"
}

function verbose() {
    log VERBOSE "$@"
}

function debug() {
    log DEBUG "$@"
}

function warning() {
    local message=$1

    echo_color YELLOW "WARNING: ${message}"
}

function error() {
    local message=$1

    echo_color RED "ERROR: ${message}"
}

MY_REPO=nicholasdille/packages
MY_VERSION=master

: "${CACHE_DIR:=${HOME}/.local/var/cache/pkgctl}"
: "${DOWNLOAD_DIR:=${CACHE_DIR}/download}"

: "${TARGET_BASE:=/usr/local}"
: "${TARGET_BIN:=${TARGET_BASE}/bin}"
: "${TARGET_COMPLETION:=${TARGET_BASE}/etc/bash_completion.d}"

: "${CURL_DOWNLOAD_SILENT:=false}"
: "${TAR_VERBOSE:=false}"
: "${ZIP_VERBOSE:=false}"

export DOCKER_BUILDKIT=1

temporary_directories=()
temporary_containers=()
cleanup_tasks=( "remove_temporary_directory" "remove_temporary_container" )

function cleanup() {
    for cleanup_task in "${cleanup_tasks[@]}"; do
        ${cleanup_task}
    done
}
trap cleanup EXIT

function remove_temporary_container() {
    if type docker >/dev/null 2>&1 && docker version >/dev/null 2>&1; then
        for container_name in "${temporary_containers[@]}"; do
            docker ps --all --quiet --filter name="${container_name}" | xargs --no-run-if-empty docker rm
        done
    fi
}

function remove_temporary_directory() {
    for temporary_directory in "${temporary_directories[@]}"; do
        if test -n "${temporary_directory}" && test -d "${temporary_directory}"; then
            rm -rf "${temporary_directory:?}"
        fi
    done
}

function check_target() {
    verbose "Checking existence of target directory <${TARGET_BASE}>"
    if ! test -d "${TARGET_BASE}"; then
        error "Target directory <${TARGET_BASE}> does not exist. Please create it first."
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
            verbose "Target directory requires root access."
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
        verbose "Sudo requires a password"
        return 0
    fi
    return 1
}

function unlock_sudo() {
    if target_requires_sudo; then
        if sudo_requires_password; then
            silent "Please enter your password to unlock sudo for the installation."
            sudo true
        else
            verbose "Sudo does not require a password (this time)."
        fi
    fi

    create_target
}

function download() {
    local url=$1
    if test -z "${url}"; then
        error "URL must be specified."
        exit 1
    fi

    local hash
    hash=$(echo "${url}" | sha256sum | cut -d' ' -f1)

    if ! test -d "${DOWNLOAD_DIR}/${hash}"; then
        mkdir -p "${DOWNLOAD_DIR}/${hash}"
        pushd "${DOWNLOAD_DIR}/${hash}"
        echo "${url}" >url
        verbose "Downloading file from <${url}>..."
        curl --location --fail --remote-name "${url}"
        popd
    fi

    find "${DOWNLOAD_DIR}/${hash}" -type f | \
        grep -vE "/url$" | \
        while read -r FILE; do
            cp "${FILE}" "${temporary_directory}"
        done
}

function unpack() {
    local filename=$1
    if test -z "${filename}"; then
        error "Filename must be specified."
        exit 1
    fi
    shift
    if ! test -s "${temporary_directory}/${filename}"; then
        error "Filename must exist."
        exit 1
    fi
    local parameters=("$@")

    : "${COMPRESSION_PARAMETER:=-z}"

    verbose "Unpacking asset to temporary directory..."
    if test "${#parameters[*]}" -gt 0; then
        debug "  Including parameters <${parameters[*]}>"
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
        error "Filename must be specified."
        exit 1
    fi
    shift
    if ! test -s "${temporary_directory}/${filename}"; then
        error "Filename must exist."
        exit 1
    fi

    verbose "Unpacking asset in temporary directory..."
    gunzip "${temporary_directory}/${filename}"
}

function install_file() {
    local filename=$1
    if test -z "${filename}"; then
        error "Filename must be specified."
        exit 1
    fi
    shift
    local mode=$1
    if test -z "${mode}"; then
        mode=0644
    fi

    if test -z "${TARGET}"; then
        error "Target must not be empty."
        exit 1
    fi

    local FILES=""
    if test -d "${temporary_directory}/${filename}"; then
        debug "Filename points to a directory."
        FILES="$(find "${temporary_directory}/${filename}" -maxdepth 1 -type f)"

    elif test -s "${temporary_directory}/${filename}"; then
        debug "Filename points to a non-empty file."
        FILES="${temporary_directory}/${filename}"

    else
        error "Unable to determine type of <${filename}> (neither file nor directory)."
        exit 1
    fi

    ${SUDO} install --directory "${TARGET}"
    echo "${FILES}" | \
        while read -r binary; do
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

function install_node_module() {
    ${SUDO} npm install "${NODE_PARAMS[@]}" "$@"
}

function install_python_module() {
    ${SUDO} pip3 install --upgrade "$@"
}

function install_ruby_module() {
    ${SUDO} gem install "$@"
}

function install_crate() {
    ${SUDO} env CARGO_HOME="${TARGET_BASE}" cargo install "$@"
}

function get_package_definition() {
    local package=$1
    if test -z "${package}"; then
        error "No package specified."
        exit 1
    fi

    # shellcheck disable=SC2154
    if test -f "${working_directory}/${package}/package.yaml"; then
        debug "Using local package.yaml"

        if test "$(yq --version | sed -E "s/^yq\sversion\s([0-9]+)\..+$/\1/")" == "3"; then
            yq --tojson read "${working_directory}/${package}/package.yaml"

        elif test "$(yq --version | sed -E "s/^yq\sversion\s([0-9]+)\..+$/\1/")" == "4"; then
            yq --tojson eval '.' "${working_directory}/${package}/package.yaml"

        else
            error "Unable to determine version of yq."
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
        error "No package specified."
        exit 1
    fi

    PACKAGE_JSON=$(cat "${temporary_directory}/package.json")

    local version_command
    version_command=$(
        echo "${PACKAGE_JSON}" | \
            jq --raw-output .version.command
    )
    if test -z "${version_command}" || test "${version_command}" == "null"; then
        warning "No version command specified for package <${package}>."
        return
    fi

    local version_filter
    version_filter=$(
        echo "${PACKAGE_JSON}" | \
            jq --raw-output '.version.filter'
    )
    if test -z "${version_filter}" || test "${version_filter}" == "null"; then
        warning "No version filter specified for package <${package}>."
        return
    fi

    local version_pattern
    version_pattern=$(
        echo "${PACKAGE_JSON}" | \
            jq --raw-output '.version.pattern'
    )
    if test -z "${version_pattern}" || test "${version_pattern}" == "null"; then
        warning "No version pattern specified for package <${package}>."
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
        error "No package specified."
        exit 1
    fi

    # shellcheck disable=SC2002
    cat "${temporary_directory}/package.json" | \
        jq --raw-output '.version.latest'
}

function requested_version_installed() {
    local package=$1
    if test -z "${package}"; then
        error "No package specified."
        exit 1
    fi
    local requested_version=$2

    local installed_version
    installed_version=$(get_installed_version "${package}")
    if test -z "${installed_version}"; then
        warning "Unable to determine installed version."
        return 1
    fi

    if test -z "${requested_version}"; then
        requested_version=$(get_latest_version "${package}")
        if test -z "${requested_version}"; then
            warning "Unable to determine latest version."
            return 1
        fi
    fi

    verbose "Comparing installed version ${installed_version} with version ${requested_version}..."
    if test "${installed_version}" == "${requested_version}"; then
        return 0
    else
        return 1
    fi
}

function check_installed_version() {
    local package=$1
    if test -z "${package}"; then
        error "No package specified."
        exit 1
    fi
    local requested_version=$2

    if requested_version_installed "${package}" "${requested_version}"; then
        info "Latest version of ${package} is already installed."
        exit
    fi
}

function get_install_script() {
    local package=$1
    if test -z "${package}"; then
        error "No package specified."
        exit 1
    fi

    # shellcheck disable=SC2002
    cat "${temporary_directory}/package.json" | \
        jq \
            --raw-output \
            '.install.script'
}

function package_needs_docker() {
    local package=$1
    if test -z "${package}"; then
        error "No package specified."
        exit 1
    fi

    local needs_docker
    # shellcheck disable=SC2002
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

function add_prefix() {
    local prefix=$1

    if test -z "${prefix}"; then
        error "Prefix must be supplied."
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
        verbose "Using authentication for GitHub"
        GITHUB_AUTH_PARAMETER=("--header" "Authorization: token ${GITHUB_TOKEN}")
    else
        if ! github_rate_limit_ok; then
            error "Rate limit exceeded"
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
        error "Project not specified."
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

    verbose "GitHub rate limit ${GITHUB_RATE_REMAINING}/${GITHUB_RATE_LIMIT} remaining"
    if test "${GITHUB_RATE_REMAINING}" -eq 0; then
        warning "GitHub rate limit exceeded (resets as $(date -d "@${GITHUB_RATE_RESET}"))"
        return 1
    fi

    return 0
}

function github_check_rate_limit() {
    if ! github_rate_limit_ok; then
        error "GitHub rate limit exceeded"
        exit 1
    fi
}

function github_get_releases() {
    local project=$1

    if test -z "${project}"; then
        error "Project not specified."
        return 1
    fi

    verbose "Fetching releases for ${project}..."
    github_api_repo "${project}" "/releases"
}

function check_docker() {
    if ! type docker >/dev/null 2>&1; then
        error "Docker is required but was not found."
        exit 1
    fi
    if ! docker version >/dev/null 2>&1; then
        error "Docker daemon is not running"
        exit 1
    fi
}

function build_containerized() {
    local image=$1
    shift
    local command=("$@")

    if test -z "${image}"; then
        error "Image not specified."
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
        verbose "Using local copy of packages.json in current directory. If you are not a contributor, please run <pkg cache>."
        cat packages.json

    else
        error "Unable to find packages.json. Run <pkg cache> first."
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
        error "Failed to determine tag from version ${VERSION}."
        exit 1
    fi

    mkdir -p "${HOME}/.pkgctl"
    info "Using version ${TAG}."
    curl --silent "https://api.github.com/repos/${MY_REPO}/releases/tags/${TAG}" | \
        jq --raw-output '.assets[] | select(.name == "packages.json") | .browser_download_url' | \
        xargs curl --silent --location --output "${HOME}/.pkgctl/packages.json"
}

function handle_file() {
    package=$1

    if test -z "${package}"; then
        error "No package specified."
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
        error "No package specified."
        show_help_install
        exit 1
    fi

    get_packages | \
        jq --arg package "${package}" '.packages[] | select(.name == $package)'
}

function install_package() {
    local package=$1
    if test -z "${package}"; then
        error "Package name must be specified."
        exit 1
    fi
    local requested_version=$2

    export PACKAGE_NAME=${package}

    temporary_directory=$(mktemp -d)
    # shellcheck disable=SC2164
    cd "${temporary_directory}"
    temporary_directories+=( "${temporary_directory}" )

    container_name=$(basename "$(mktemp --dry-run)")
    temporary_containers+=( "${container_name}" )

    get_package_definition "${package}" >"${temporary_directory}/package.json"
    if ! test -s "${temporary_directory}/package.json"; then
        error "Package <${package}> does not exist."
        exit 1
    fi
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
        warning "This is a forced installation."
    else
        if requested_version_installed "${package}" "${requested_version}"; then
            info "Requested version ${requested_version} of ${package} is already installed."
            return
        fi
    fi

    if package_needs_docker "${package}"; then
        check_docker
        cleanup_tasks+=("remove_temporary_container")
    fi
    unlock_sudo

    for filename in $(jq --raw-output 'select(.files != null) | .files[].name' "${temporary_directory}/package.json"); do
        verbose "Injecting file <${filename}>..."
        jq --raw-output --arg name "${filename}" '.files[] | select(.name == $name) | .content' "${temporary_directory}/package.json" >"${temporary_directory}/${filename}"
    done

    install_script="$(get_install_script "${package}")"
    if test -z "${requested_version}"; then
        if echo "${install_script}" | grep requested_version; then
            error "Requested package version is empty but install script uses it."
            exit 1
        fi
    fi

    quiet "Installing ${package} version ${requested_version:-UNKNOWN}..."

    eval "${install_script}"

    info "Finished installation of ${package} version ${requested_version:-UNKNOWN}."
}

function get_deps() {
    local package=$1

    local my_deps
    my_deps=$(
        get_package_definition "${package}" | \
            jq \
                --raw-output \
                --arg package "${package}" \
                'select(.install.requires != null) | .install.requires[]'
    )

    local needs_docker
    needs_docker=$(
        get_package_definition "${package}" | \
            jq \
                --raw-output \
                --arg package "${package}" \
                'select(.install.docker != null) | .install.docker'
    )
    if ! test -z "${needs_docker}"; then
        deps=( "docker" "${deps[@]}" )
    fi

    for my_dep in ${my_deps}; do
        deps=( "${my_dep}" "${deps[@]}" )

        get_deps "${my_dep}"
    done
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
            error "File does not exist."
            exit 1
        fi
        # shellcheck disable=SC2046
        set -- $(cat "${file}") "$@"
    fi

    if test "$#" -eq 0; then
        error "No package specified."
        show_help_install
        exit 1
    fi

    if ! test -f "${HOME}/.pkgctl/packages.json"; then
        handle_cache
    fi

    working_directory="${PWD}"

    packages=()
    until test "$#" -eq 0; do
        packages=( "$1" "${packages[@]}" )
        shift
    done

    deps=()
    for package_spec in "${packages[@]}"; do
        local package
        package=$(echo "${package_spec}" | cut -d@ -f1)
        local requested_version
        requested_version=$(echo "${package_spec}" | cut -d@ -f2)
        if test "${requested_version}" == "${package}"; then
            unset requested_version
        fi

        deps=( "${package_spec}" "${deps[@]}" )
        get_deps "${package}"
    done

    for package_spec in "${deps[@]}"; do
        local package
        package=$(echo "${package_spec}" | cut -d@ -f1)
        local requested_version
        requested_version=$(echo "${package_spec}" | cut -d@ -f2)
        if test "${requested_version}" == "${package}"; then
            unset requested_version
        fi

        echo
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
        error "No search term specified."
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
        error "No package specified."
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
        >&2 error "No version command specified for package <${package}>."
        return
    fi

    version_filter=$(
        echo "${package_json}" | \
            jq --raw-output '.version.filter'
    )
    if test -z "${version_filter}" || test "${version_filter}" == "null"; then
        >&2 error "No version filter specified for package <${package}>."
        return
    fi

    version_pattern=$(
        echo "${package_json}" | \
            jq --raw-output '.version.pattern'
    )
    if test -z "${version_pattern}" || test "${version_pattern}" == "null"; then
        >&2 error "No version pattern specified for package <${package}>."
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
            --log-level)
                LOG_LEVEL=${1^^}
                LOG_LEVEL_ID=$(get_log_level_id "${LOG_LEVEL}")
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
        error "Do not source this script."
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
