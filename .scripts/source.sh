if test "$0" == "bash"; then
    >&2 echo "ERROR: Do not source this file."
    exit 1
fi

SCRIPT_BASE_DIR=$(dirname $(readlink -f "$0"))

: "${SOURCE_LOCAL_FILES:=false}"

>&2 echo "Sourcing variables..."
if ${SOURCE_LOCAL_FILES}; then
    >&2 echo "  !!! FROM LOCAL FILE !!!"
    source "${SCRIPT_BASE_DIR}/../.scripts/variables.sh"
else
    source <(curl --silent --location --fail https://pkg.dille.io/.scripts/variables.sh)
fi

for file in linux github; do
    >&2 echo "Sourcing ${file}..."

    if ${SOURCE_LOCAL_FILES}; then
        >&2 echo "  !!! FROM LOCAL FILE !!!"
        source "${SCRIPT_BASE_DIR}/../.scripts/${file}.sh"
    else
        source <(curl --silent --location --fail https://pkg.dille.io/.scripts/${file}.sh)
    fi
done