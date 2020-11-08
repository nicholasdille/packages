#!/bin/bash

for lib in variables control linux github codeberg docker; do
    if test -f "${working_directory}/.scripts/${lib}.sh"; then
        source "${working_directory}/.scripts/${lib}.sh"
    else
        source "${HOME}/.pkg/${lib}.sh"
    fi
done