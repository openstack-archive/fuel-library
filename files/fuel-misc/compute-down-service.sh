#!/bin/bash
###############################################################################
#
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
#
###############################################################################
set -e

usage() {
  cat <<EOF
Usage: $(basename $0) [-?] <list|clean>

Arguments:
  list - list the current downed services
  clean - remove all services currently marked down
EOF
  exit 1
}

while getopts ":" opt; do
  case $opt in
    \?)
        usage
        ;;
  esac
done
shift "$((OPTIND-1))"

list() {
    nova service-list | awk 'BEGIN { FS="|" } { gsub(/ /, ""); if ($7 == "down") { print $0 } }'
}

clean() {
    for ID in $(nova service-list | awk 'BEGIN { FS="|" } { gsub(/ /, ""); if ($7 == "down") { print $7 } }'); do
        nova service-delete $ID
    done
}

if [ -z "$1" ]; then
    usage
fi

case $1 in
  list)
      list
      ;;
  clean)
      clean
      ;;
  *)
      usage
      ;;
esac
