#!/bin/bash

set -o errexit

pip3 install --upgrade termtosvg

cat <<EOF
Record: termtosvg -t progress_bar myfile.svg
Convert from asciinema: termtosvg render test.cast test.svg
EOF
