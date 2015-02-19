#!/bin/bash

#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -eu

ROOT=$(dirname $(readlink -f $0))
WORK_DIR="${ROOT}/../../deployment"
UTILS_DIR="${ROOT}"
TOX_CONF="${ROOT}/tox.ini"
#which Python envs (py26, py26, etc.) use for tests
TOX_PYENVS=${TOX_PYENVS:-"py26"}

certain_tests=()
flake8_checks=1
only_flake8_checks=0
python_tests=1
testropts=""


check_tox() {
  type tox >/dev/null 2>&1 || { echo >&2 "Tox is required to be installed to run tests."; exit 1; }
}

usage() {
  echo "Usage: $0 [OPTIONS] [-- TESTR OPTIONS]"
  echo "Run Python tests for fuel-library"
  echo ""
  echo "  -p, --pep8           Run only flake8 checks."
  echo "  -P, --no-pep8        Do not run flake8 tests"
  echo "  -t, --tests          Select tests to run. Could be specified"
  echo "                       multiple times to select multiple tests"
  echo "  -h, --help           Print this usage message and exit."
  exit
}


process_options() {
    TEMP=$(getopt \
        -o hpPt: \
        --long help,pep8,no-pep8,tests: \
        -n 'run_tests.sh' -- "$@")


    eval set -- "$TEMP"

    while true ; do
      case "$1" in
        -p|--pep8) only_flake8_checks=1;        shift 1;;
        -P|--no-pep8) flake8_checks=0;          shift 1;;
        -h|--help) usage;                       shift 1;;
        -t|--tests) certain_tests+=("$2");      shift 2;;
        # All parameters and alien options will be passed to testr
        --) shift 1; testropts+="$@";
          break;;
        *) >&2 echo "Internal error: got \"$1\" argument.";
          usage; exit 1
      esac

    done

    # Check that specified test file/dir exists. Fail otherwise.
    if [[ ${#certain_tests[@]} -ne 0 ]]; then
      for test in ${certain_tests[@]}; do
        local file_name=${test%:*}
        echo $file_name

        if [[ ! -f $file_name ]] && [[ ! -d $file_name ]]; then
          >&2 echo "Error: Specified tests were not found."
          #exit 1
        fi
      done
    fi

}


run_cleanup() {
  echo "Doing a clean up."
  find . -type f -name "*.pyc" -delete
}


# run pep8 checks
run_flake8() {
  echo "Starting flake8 checks..."

  tox -e pep8 -c $TOX_CONF -- $testropts $WORK_DIR
}


# run tests
run_tests() {
  echo "Starting Python tests..."
  local tests=$WORK_DIR

  if [[ ${#certain_tests[@]} -ne 0 ]]; then
    tests=${certain_tests[@]}
  fi

  tox -e $TOX_PYENVS -c $TOX_CONF -- -v $testropts $tests
}


run() {
  local errors=""

  run_cleanup

  #if flake8 is not disabled or only flake8
  if [[ $only_flake8_checks -eq 1 ]];  then
    flake8_checks=1
    python_tests=0
  fi

  if [[ $flake8_checks -eq 1 ]]; then
    run_flake8 || errors+=" flake8"
  fi

  if [[ $python_tests -eq 1 ]]; then
    run_tests || errors+=" Python"
  fi

  # print failed tests
  if [[ -n "$errors" ]]; then
    echo Failed tests: $errors
    exit 1
  fi
}

check_tox
process_options $@
run
