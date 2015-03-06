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



type tasks-validator >/dev/null 2>&1 || { echo >&2 "fuel-tasks-validator is required to be installed to run tests."; exit 1; }

echo "Starting tasks-validator..."
tasks-validator -d $WORK_DIR
