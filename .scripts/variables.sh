#!/bin/bash

: "${TARGET_BASE:=/usr/local}"
: "${TARGET_BIN:=${TARGET_BASE}/bin}"
: "${TARGET_COMPLETION:=${TARGET_BASE}/etc/bash_completion.d}"

: "${CURL_DOWNLOAD_SILENT:=false}"
: "${TAR_VERBOSE:=false}"
: "${ZIP_VERBOSE:=false}"

# shellcheck disable=SC2034
PACKAGE="$(basename "${SCRIPT_BASE_DIR}")"