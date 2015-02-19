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
PUPPET_DIR="${ROOT}/../../deployment"
UTILS_DIR="${ROOT}"
TOX_CONF="${ROOT}/tox.ini"
TESTER_OPTIONS="-v -s"

# cehck tox presence

# run pep8 checks
function run_pep8 {
  tox -e pep8 -c $TOX_CONF -- $PUPPET_DIR || echo "Failed tests: pep8 checks"
}

# run tests
function run_tests {
  tox -e py26 -c $TOX_CONF -- $TESTER_OPTIONS $PUPPET_DIR
}


run_pep8
run_tests
