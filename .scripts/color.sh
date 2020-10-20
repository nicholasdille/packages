#!/bin/bash

# shellcheck disable=SC2034
DEFAULT="\e[39m\e[49m"
# shellcheck disable=SC2034
LIGHT_GRAY="\e[37m"

# shellcheck disable=SC2034
DARK_GRAY="\e[90m"
# shellcheck disable=SC2034
RED="\e[91m"
# shellcheck disable=SC2034
GREEN="\e[92m"
# shellcheck disable=SC2034
YELLOW="\e[93m"
# shellcheck disable=SC2034
BLUE="\e[94m"
# shellcheck disable=SC2034
MAGENTA="\e[95m"
# shellcheck disable=SC2034
CYAN="\e[96m"

# shellcheck disable=SC2034
BG_DARKGRAY="\e[100m"
# shellcheck disable=SC2034
BG_RED="\e[101m"
# shellcheck disable=SC2034
BG_GREEN="\e[102m"
# shellcheck disable=SC2034
BG_YELLOW="\e[103m"
# shellcheck disable=SC2034
BG_BLUE="\e[104m"
# shellcheck disable=SC2034
BG_MAGENTA="\e[105m"
# shellcheck disable=SC2034
BG_CYAN="\e[106m"

function echo_color() {
    local color=$1
    local message=$2

    echo -e "${!color}${message}${DEFAULT}"
}