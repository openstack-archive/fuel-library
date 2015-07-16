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
#
# update_modules.sh
#
#  This script uses librarian-puppet to populate the puppet folder with
#  upstream puppet modules.  By default, it assumes librarian-puppet is already
#  available to the environment or it will fail. You can provide command line
#  options to have the script use bundler and install librarian-puppet if
#  neccessary.
#
# Parameters:
#  -b - Use bundler to install librarian-puppet (optional)
#  -p <puppet_version> - Puppet version to use with bundler (optional)
#  -l <librarian_tmp> - Folder for tmp cache for librarian-puppet (optional)
#  -h <bundle_dir> - Folder to be used as the h ome directory for bundler (optional)
#  -v - Verbose printing, turns on set -x (optional)
#
# Variables:
#  PUPPET_GEM_VERSION - the version of puppet to be pulled down by bundler
#                       Defaults to '3.4.3'
#  LIBRARIAN_TMP - The librarian tmp cache folder to use.
#                  Defaults to '/var/tmp/.librarian_tmp'
#  BUNDLE_DIR - The folder to store the bundle gems in.
#               Defaults to '/var/tmp/.bundle_home'
#
#  NOTE: These variables can be overriden via bash environment variable with the
#        same name or via the command line paramters.
#
# Author: Alex Schultz <aschultz@mirantis.com>
#
###############################################################################
set -e

usage() {
  cat <<EOF
  Usage: $(basename $0) [-b] [-p <puppet_version>] [-l <librarian_tmp>] [-h <bundle_dir>]

Options:
  -b - Use bundler instead of assuming librarian-puppet is available
  -p <puppet_version> - Puppet version to use with bundler
  -l <librarian_tmp> - Folder for tmp cache for librarian-puppet
  -h <bundle_dir> - Folder to be used as the home directory for bundler
  -v - Verbose printing of commands

EOF
  exit 1
}
while getopts ":bp:l:h:v" opt; do
  case $opt in
    b)
      USE_BUNDLER=true
      BUNDLER_EXEC="bundle exec"
      ;;
    p)
      PUPPET_GEM_VERSION=$OPTARG
      ;;
    l)
      LIBRARIAN_TMP=$OPTARG
      ;;
    h)
      BUNDLE_DIR=$OPTARG
      ;;
    v)
      set -x
      ;;
    \?)
      usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done
shift "$((OPTIND-1))"

DEPLOYMENT_DIR=`dirname $0`
PUPPET_GEM_VERSION=${PUPPET_GEM_VERSION:-'3.4.3'}
LIBRARIAN_TMP=${LIBRARIAN_TMP:-'/var/tmp/.librarian_tmp'}
BUNDLE_DIR=${BUNDLE_DIR:-'/var/tmp/.bundle_home'}

# We need to be in the deployment directory to run librarian-puppet
cd $DEPLOYMENT_DIR

if [ "$USE_BUNDLER" = true ]; then
  # ensure bundler is installed
  bundle --version

  # update bundler modules
  bundle update
fi

# set the temp directory for global librarian config
$BUNDLER_EXEC librarian-puppet config --global tmp $LIBRARIAN_TMP

# run librarian-puppet update to populate the modules
$BUNDLER_EXEC librarian-puppet update

# run librarian-puppet show to list the modules being managed and their versions
$BUNDLER_EXEC librarian-puppet show
