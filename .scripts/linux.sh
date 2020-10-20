#!/bin/bash

function target_requires_sudo() {
    # target directory is root-owned
    if test "$(stat "${TARGET_BASE}" -c '%u:%g')" == "0:0"; then

        # we are not root right now
        if test "$(id -u)" != "0"; then
            warning "Target directory requires root access."
            return 0
        fi
    fi

    # otherwise no sudo is required
    return 1
}

function sudo_requires_password() {
    if ! sudo -n true 2>&1; then
        log VERBOSE "Sudo requires a password"
        return 0
    fi
    return 1
}

function unlock_sudo() {
    if target_requires_sudo; then
        if sudo_requires_password; then
            log INFO "Please enter your password to unlock sudo for the installation."
            sudo true
        else
            log VERBOSE "Sudo does not require a password (this time)."
        fi
    fi
}

function download_file() {
    if ! test -f "${PACKAGES_TEMP_DIR}/download_file.txt"; then
        error "No download URL was provided."
        exit 1
    fi

    if ${CURL_DOWNLOAD_SILENT}; then
        CURL_ADDITIONAL_PARAMS="--silent"
    fi

    log INFO "Downloading file..."
    pushd "${PACKAGES_TEMP_DIR}" >/dev/null
    cat "${PACKAGES_TEMP_DIR}/download_file.txt" | \
        xargs curl --location --fail --remote-name --continue-at - ${CURL_ADDITIONAL_PARAMS}
    popd
}

function untar_file() {
    local file=$1
    shift
    local target=$1
    shift
    local parameters=("$@")

    if test -z "${target}"; then
        target=${TARGET_BIN}
    fi

    if ${TAR_VERBOSE}; then
        TAR_ADDITIONAL_PARAMS="-v"
    fi

    log INFO "Unpacking asset to directory ${TARGET_BIN}..."
    log VERBOSE "  Including parameters <${parameters[*]}>"
    sudo tar -xzf "${PACKAGES_TEMP_DIR}/${file}" -C "${target}" \
        ${TAR_ADDITIONAL_PARAMS} \
        "${parameters[@]}"
}

function unxz_file() {
    local parameters=("$@")

    if ${TAR_VERBOSE}; then
        TAR_ADDITIONAL_PARAMS="-v"
    fi

    >&2 echo "Unpacking asset to directory ${TARGET_BIN}..."
    >&2 echo "  Including parameters <${parameters[*]}>"
    cat | \
        sudo tar -x -J ${TAR_ADDITIONAL_PARAMS} -C "${TARGET_BIN}" "${parameters[@]}"
}

function unzip_file {
    local file=$1
    shift
    local filter=("$@")

    ZIP_ADDITIONAL_PARAMS="-q"
    if ${TAR_VERBOSE}; then
        ZIP_ADDITIONAL_PARAMS="-v"
    fi

    sudo unzip -o ${ZIP_ADDITIONAL_PARAMS} -d "${TARGET_BIN}" "${file}" "${filter[@]}"
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
        sudo tee "${dirname}/${filename}" >/dev/null
    echo "${dirname}/${filename}"
}

function make_executable() {
    local filename=$1

    if test -z "${filename}"; then
        cat | while read -r filename2; do
            >&2 echo "Setting executable bits on ${filename2}"
            sudo chmod +x "${filename2}"
        done
        return
    fi

    >&2 echo "Setting executable bits on ${filename}"
    sudo chmod +x "${TARGET_BIN}/${filename}"
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
    sudo mv "${TARGET_BIN}/${old_name}" "${TARGET_BIN}/${new_name}"
}

function store_completion() {
    local filename=$1

    if test -z "${filename}"; then
        echo "ERROR: File name not specified."
        return 1
    fi

    sudo mkdir -p "${TARGET_COMPLETION}"

    cat | \
        store_file "${filename}.sh" "${TARGET_COMPLETION}"
    sudo ln -sf "${TARGET_COMPLETION}/${filename}.sh" /etc/bash_completion.d/
}