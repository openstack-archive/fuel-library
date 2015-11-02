#!/usr/bin/env bash
set -x

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"
FUEL_LIBRARY_PATH="$(dirname "$(readlink -f "$SCRIPT_PATH/..")")"
MODULES_PATH="$FUEL_LIBRARY_PATH/deployment/puppet"

cd "$FUEL_LIBRARY_PATH"

while getopts ':a' opt; do
  case $opt in
    a) ALL=1 ;;
  esac
done

if [[ $ALL -eq 1 ]]; then
  files=("$MODULES_PATH/osnailyfacter/")
else
  files=($(git diff --name-only HEAD~1 | grep 'osnailyfacter/.*.pp$'))
fi

if [[ $files ]]; then
  grep 'hiera_array(.*[A-Za-z]_roles.*)' ${files[@]}
  exitcode=$?
else
  exit 0
fi

if [[ $exitcode -eq 0 ]]; then
  exit 1
else
  exit 0
fi
