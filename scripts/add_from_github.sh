#!/bin/bash
set -o errexit

repo=$1
if test -z "${repo}"; then
    echo "ERROR: You must sdpecify a GitHub repository (<owner>/<repo>)."
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

json="$(curl --silent --header "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${repo}")"

name="$(
    echo "${json}" | \
        jq --raw-output '.name'
)"
description="$(
    echo "${json}" | \
        jq --raw-output '.description'
)"

releases="$(curl --silent --header "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${repo}/releases" | jq 'length')"
if test "${releases}" -gt 0; then
    renovate_source=releases

    has_release="$(curl --silent --header "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${repo}/releases" | jq 'map(select(.prerelease == false)) | length')"
    if test "${has_release}" -gt 0; then
        latest_version="$(curl --silent --header "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${repo}/releases/latest" | jq --raw-output '.tag_name')"
    else
        latest_version="$(curl --silent --header "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${repo}/releases" | jq --raw-output '.[0].tag_name')"
    fi

    asset=$(
        curl --silent --header "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${repo}/releases/tags/${latest_version}" | \
            jq --raw-output '.assets[].browser_download_url' | \
            tr '\n' ' ' | \
            sed "s/${latest_version}/\$\{requested_version\}/g" | \
            sed "s|${repo}|\$\{PACKAGE_NAME\}|g"
    )

else
    renovate_source=tags
    latest_version="$(curl --silent --header "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${repo}/tags" | jq --raw-output '.[0].name')"
fi

cat <<EOF
name: ${name}
description: ${description}
repo: ${repo}
version:
  latest: ${latest_version} # renovate: datasource=github-${renovate_source} depName=${repo}
tags:
- TODO
install:
  script: |-
    download "${asset}"
EOF