function target_requires_sudo() {
    # target directory is root-owned
    if test "$(stat ${TARGET} -c '%u:%g')" == "0:0"; then

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
            echo "Please enter your password to unlock sudo for the installation."
            sudo true
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
    local filter=$@

    if ${TAR_VERBOSE}; then
        TAR_ADDITIONAL_PARAMS="-v"
    fi

    >&2 echo "Unpacking asset to directory ${directory}..."
    >&2 echo "  Including <${filter}>"
    cat | \
        sudo tar -x -z ${TAR_ADDITIONAL_PARAMS} -C ${TARGET}/bin ${filter}
}