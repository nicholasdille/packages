function target_requires_sudo() {
    # target directory is root-owned
    if test "$(stat "${TARGET_BASE}" -c '%u:%g')" == "0:0"; then

        # we are not root right now
        if test "$(id -u)" != "0"; then
            >&2 echo "Target directory requires root access."
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
    local parameters=$@

    if ${TAR_VERBOSE}; then
        TAR_ADDITIONAL_PARAMS="-v"
    fi

    >&2 echo "Unpacking asset to directory ${directory}..."
    >&2 echo "  Including parameters <${parameters}>"
    cat | \
        sudo tar -x -z ${TAR_ADDITIONAL_PARAMS} -C ${TARGET_BIN} ${parameters}
}

function unxz_file() {
    local parameters=$@

    if ${TAR_VERBOSE}; then
        TAR_ADDITIONAL_PARAMS="-v"
    fi

    >&2 echo "Unpacking asset to directory ${directory}..."
    >&2 echo "  Including parameters <${parameters}>"
    cat | \
        sudo tar -x -J ${TAR_ADDITIONAL_PARAMS} -C ${TARGET_BIN} ${parameters}
}

function unzip_file {
    local file=$1
    shift
    local filter=$@

    ZIP_ADDITIONAL_PARAMS="-q"
    if ${TAR_VERBOSE}; then
        ZIP_ADDITIONAL_PARAMS="-v"
    fi

    sudo unzip -o ${ZIP_ADDITIONAL_PARAMS} -d ${TARGET_BIN} ${file} ${filter}
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
        dirname=${TARGET_BIN}
    fi

    >&2 echo "Creating file ${dirname}/${filename}"
    cat | \
        sudo tee ${dirname}/${filename} >/dev/null
    echo ${dirname}/${filename}
}

function make_executable() {
    local filename=$1

    if test -z "${filename}"; then
        cat | while read filename; do
            >&2 echo "Setting executable bits on ${filename}"
            sudo chmod +x ${filename}
        done
        return
    fi

    >&2 echo "Setting executable bits on ${filename}"
    sudo chmod +x ${TARGET_BIN}/${filename}
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
    sudo mv ${TARGET_BIN}/${old_name} ${TARGET_BIN}/${new_name}
}

function store_completion() {
    local filename=$1

    if test -z "${filename}"; then
        echo "ERROR: File name not specified."
        return 1
    fi

    sudo mkdir -p ${TARGET_COMPLETION}

    cat | \
        store_file ${filename}.sh ${TARGET_COMPLETION}
    sudo ln -sf ${TARGET_COMPLETION}/${filename}.sh /etc/bash_completion.d/
}