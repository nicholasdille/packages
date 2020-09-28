BASE_DIR=$(dirname $(readlink -f "$0"))

: "${SOURCE_LOCAL_SCRIPTS:=false}"

: "${TARGET:=/usr/local}"

: "${CURL_DOWNLOAD_SILENT:=true}"
: "${TAR_VERBOSE:=false}"

for file in github; do
    >&2 echo "Sourcing ${file}..."

    if ${SOURCE_LOCAL_SCRIPTS}; then
        >&2 echo "  !!! FROM LOCAL FILE !!!"
        source "${BASE_DIR}/../.scripts/${file}.sh"
    else
        source <(curl --silent --location --fail https://pkg.dille.io/.scripts/${file}.sh)
    fi
done