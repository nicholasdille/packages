function add_prefix() {
    local prefix=$1

    if test -z "${prefix}"; then
        echo "ERROR: Prefix must be supplied."
        exit 1
    fi

    cat | while read LINE; do
        echo "${prefix}: ${LINE}"
    done
}

function run_filters() {
    local filters=("$@")

    # slurp input
    IFS='' read -r -d '' data

    for i in ${!filters[*]}; do
        >&2 echo "Applying filter $i <${filters[$i]}>..."

        # apply filter and store output
        DATA=$(echo "${data}" | eval "${filters[$i]}")
    done
    echo "${data}"
}

function run_tasks() {
    local jobs=("$@")

    # slurp input
    IFS='' read -r -d '' data

    for i in ${!jobs[*]}; do
        echo "${data}" | eval "${jobs[$i]} | add_prefix $i"
    done
}