#!/bin/bash

function _update_ps1() {
    PS1="$("${TARGET_BIN}/powerline-go" -theme "${HOME}/.local/etc/powerline-go-theme.json" -error $? -modules exit,user,cwd,git,docker-context,kube,jobs -newline)"
}
PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"