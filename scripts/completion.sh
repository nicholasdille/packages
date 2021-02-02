#!/bin/bash

function _pkgctl() {
    local command=${COMP_WORDS[1]}
    local cur=${COMP_WORDS[COMP_CWORD]}
    local prev=${COMP_WORDS[COMP_CWORD-1]}

    #echo "command=${command},cur=${cur},prev=${prev}."

    case "${command}" in
        install)
            case "${prev}" in
                --file)
                    _filedir
                    ;;
                *)
                    options=( --force --file )
                    packages="$(jq --raw-output '.packages[].name' packages.json)"
                    COMPREPLY=( "$(compgen -W "${packages} ${options[*]}" -- "${cur}")" )
                    ;;
            esac
            ;;
        file)
            if test "${prev}" == "file"; then
                packages="$(jq --raw-output '.packages[] | select(.files != null) | .name' packages.json)"
                COMPREPLY=( "$(compgen -W "${packages}" -- "${cur}")" )

            elif test "${#COMP_WORDS[@]}" == 4; then
                files="$(jq --raw-output --arg package "${COMP_WORDS[2]}" '.packages[] | select(.name == $package) | .files[].name' packages.json)"
                COMPREPLY=( "$(compgen -W "${files}" -- "${cur}")" )
            fi
            ;;
        inspect|version)
            packages="$(jq --raw-output '.packages[].name' packages.json)"
            COMPREPLY=( "$(compgen -W "${packages}" -- "${cur}")" )
            ;;
        search)
            options=( --name --desc --tags )
            COMPREPLY=( "$(compgen -W "${options[*]}" -- "${cur}")" )
            ;;
        *)
            commands=( help cache bootstrap file inspect install list search tags version )
            options=( --version )
            COMPREPLY=( "$(compgen -W "${commands[*]} ${options[*]}" -- "${cur}")" )
            ;;
    esac
}

complete -F _pkgctl pkgctl