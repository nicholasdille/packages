function github_find_latest_release() {
    local project=$1

    if test -z "${project}"; then
        echo "ERROR: Project not specified."
        return 1
    fi

    GITHUB_AUTH_PARAMETER=""
    if test -n "${GITHUB_USER}" && test -n "${GITHUB_TOKEN}"; then
        GITHUB_AUTH_PARAMETER="--user \"${GITHUB_USER}:${GITHUB_TOKEN}\""
    fi

    >&2 echo "Fetching latest release for ${project}..."
    curl ${GITHUB_AUTH_PARAMETER} --silent https://api.github.com/repos/${project}/releases/latest
}

function github_select_asset_by_name() {
    local asset_name=$1

    if test -z "${asset_name}"; then
        echo "ERROR: Asset name not specified."
        return 1
    fi

    >&2 echo "Selecting asset by name..."
    cat | \
        jq --raw-output --arg asset_name "${asset_name}" '.assets[] | select(.name == $asset_name)'
}

function github_select_asset_by_suffix() {
    local asset_name_suffix=$1

    if test -z "${asset_name_suffix}"; then
        echo "ERROR: Asset name suffix not specified."
        return 1
    fi

    >&2 echo "Selecting asset by suffix..."
    cat | \
        jq --raw-output --arg asset_name_suffix "${asset_name_suffix}" '.assets[] | select(.name | endswith($asset_name_suffix))'
}

function github_select_asset_by_prefix() {
    local asset_name_prefix=$1

    if test -z "${asset_name_prefix}"; then
        echo "ERROR: Asset name prefix not specified."
        return 1
    fi

    >&2 echo "Selecting asset by suffix..."
    cat | \
        jq --raw-output --arg asset_name_prefix "${asset_name_prefix}" '.assets[] | select(.name | startswith($asset_name_prefix))'
}

function github_get_asset_download_url() {
    >&2 echo "Fetching asset download URL..."
    cat | \
        jq --raw-output '.browser_download_url'
}