#!/bin/bash

function remove_temporary_directory() {
    if test -n "${temporary_directory}" && test -d "${temporary_directory}"; then
        rm -rf "${temporary_directory:?}"
    fi
}
temporary_directory=$(mktemp -d)
cd "${temporary_directory}"
cleanup_tasks+=("remove_temporary_directory")

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
    ${SUDO} pip3 install --upgrade "$@"
}

function install_ruby_module() {
    require ruby
    ${SUDO} bash -c "source /etc/profile.d/rbenv.sh; gem install $*"
}

function get_package_definition() {
    local package=$1
    : "${package:=${PACKAGE}}"

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    if test -f "${SCRIPT_BASE_DIR}/package.yaml"; then
        >&2 echo "Using local package.yaml"
        yq --tojson read "${SCRIPT_BASE_DIR}/package.yaml"

    elif test -f "${HOME}/.pkg/packages.json"; then
        >&2 echo "Using local packages.json"
        jq --arg package "${package}" '.packages[] | select(.name == $package)' packages.json

    else
        >&2 echo "Downloading package.yaml"
        curl --silent "https://pkg.dille.io/${package}/package.yaml" | \
            yq --tojson read -
    fi
}

function get_installed_version() {
    local package=$1
    : "${package:=${PACKAGE}}"

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
        >&2 echo "ERROR: No version command specified for package <${package}>."
        return
    fi

    local version_filter
    version_filter=$(
        echo "${PACKAGE_JSON}" | \
            jq --raw-output '.version.filter'
    )
    if test -z "${version_filter}" || test "${version_filter}" == "null"; then
        >&2 echo "ERROR: No version filter specified for package <${package}>."
        return
    fi

    local version_pattern
    version_pattern=$(
        echo "${PACKAGE_JSON}" | \
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

function get_latest_version() {
    local package=$1
    : "${package:=${PACKAGE}}"

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    local PACKAGE_JSON
    PACKAGE_JSON=$(
        curl --silent "https://pkg.dille.io/${package}/package.yaml" | \
            yq --tojson read -
    )

    echo "${PACKAGE_JSON}" | \
        jq --raw-output '.version.latest'
}

function latest_version_installed() {
    local package=$1
    : "${package:=${PACKAGE}}"

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    local installed_version
    installed_version=$(get_installed_version "${package}")
    if test -z "${installed_version}"; then
        echo "ERROR: Unable to determine installed version."
        return 1
    fi

    local latest_version
    latest_version=$(get_latest_version "${package}")
    if test -z "${latest_version}"; then
        echo "ERROR: Unable to determine latest version."
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
    : "${package:=${PACKAGE}}"

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi

    if latest_version_installed "${package}"; then
        echo "Latest version of ${package} is already installed."
        exit
    fi

    echo "Newer version of ${package} available!"
}

function get_file() {
    local package=$1
    local file=$2

    : "${package:=${PACKAGE}}"

    if test -z "${package}"; then
        echo "ERROR: No package specified."
        exit 1
    fi
    if test -z "${file}"; then
        echo "ERROR: No file specified."
        exit 1
    fi

    get_package_definition "${package}" | \
        jq \
            --raw-output \
            --arg package "${package}" \
            --arg file "${file}" \
            '.files[] | select(.name == $file) | .content'
}