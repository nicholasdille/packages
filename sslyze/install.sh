#!/bin/bash

set -o errexit

pip install --upgrade sslyze
alias sslyze="python -m sslyze"
