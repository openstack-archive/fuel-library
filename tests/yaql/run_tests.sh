#!/bin/bash
set -eu
DIR=`dirname $0`
cd "${DIR}" || exit 1

check_tox() {
  type tox >/dev/null 2>&1 || { echo >&2 "Tox is required to be installed to run tests."; exit 1; }
}

run_tox() {
  echo "Run tests..."
  tox
}

check_tox
run_tox


