#!/bin/bash
set -o errexit

repo=$1
if test -z "${repo}"; then
    echo "ERROR: You must specify a GitHub repository (<owner>/<repo>)."
    exit 1
fi

remaining_rate_limit=$(
    curl --silent https://api.github.com/rate_limit | \
        jq --raw-output '.rate.remaining'
)
if test -z "${GITHUB_TOKEN}" && test "${remaining_rate_limit}" -eq 0; then
    echo "ERROR: GitHub rate limit exceeded and API token not provided."
    exit 1
fi
if test -n "${GITHUB_TOKEN}"; then
    GITHUB_AUTH_PARAM="--header \"Authorization: token ${GITHUB_TOKEN}\""
fi

json="$(curl --silent "${GITHUB_AUTH_PARAM}" "https://api.github.com/repos/${repo}")"

name="$(
    echo "${json}" | \
        jq --raw-output '.name'
)"

dirname="packages/${name:0:1}/${name}"
mkdir -p "${dirname}"
filename="${dirname}/package.yaml"

description="$(
    echo "${json}" | \
        jq --raw-output '.description'
)"

releases="$(curl --silent "${GITHUB_AUTH_PARAM}" "https://api.github.com/repos/${repo}/releases" | jq 'length')"
if test "${releases}" -gt 0; then
    renovate_source=releases

    has_release="$(curl --silent "${GITHUB_AUTH_PARAM}" "https://api.github.com/repos/${repo}/releases" | jq 'map(select(.prerelease == false)) | length')"
    if test "${has_release}" -gt 0; then
        latest_version="$(curl --silent "${GITHUB_AUTH_PARAM}" "https://api.github.com/repos/${repo}/releases/latest" | jq --raw-output '.tag_name')"
    else
        latest_version="$(curl --silent "${GITHUB_AUTH_PARAM}" "https://api.github.com/repos/${repo}/releases" | jq --raw-output '.[0].tag_name')"
    fi

    assets=$(
        curl --silent "${GITHUB_AUTH_PARAM}" "https://api.github.com/repos/${repo}/releases/tags/${latest_version}" | \
            jq --raw-output '.assets[].browser_download_url' | \
            tr '\n' ' ' | \
            sed "s/${latest_version}/\$\{requested_version\}/g" | \
            sed "s|${repo}|\$\{PACKAGE_REPOSITORY\}|g"
    )

else
    renovate_source=tags
    latest_version="$(curl --silent "${GITHUB_AUTH_PARAM}" "https://api.github.com/repos/${repo}/tags" | jq --raw-output '.[0].name')"
fi

cat >"${filename}" <<EOF
name: ${name}
description: ${description}
repo: ${repo}
version:
  latest: ${latest_version} # renovate: datasource=github-${renovate_source} depName=${repo}
tags:
- TODO
install:
  script: |-
EOF

if test -z "${assets}"; then
    cat >>"${filename}" <<EOF
    curl --silent --location https://github.com/\${PACKAGE_REPOSITORY}/archive/\${requested_version}.tar.gz | \
        tar -xz --strip-components=1
EOF

else
    for asset_url in ${assets}; do
        asset_name=$(basename "${asset_url}")

        case "${asset_name}" in
            *.tar.gz|*.tgz)
                unpack_command=untargz
                ;;
            *.tar.bz2)
                unpack_command=untarbz2
                ;;
            *.tar.xz)
                unpack_command=untarxz
                ;;
            *.zip)
                unpack_command="unzip -q"
                ;;
            *.gz)
                unpack_command=ungz
                ;;
            *)
                unpack_command=UNKNOWN
                ;;
        esac

        cat >>"${filename}" <<EOF
    download "${asset_url}"
    ${unpack_command} "${asset_name}"
EOF
    done
fi

cat >>"${filename}" <<EOF
    find . -type f
EOF
