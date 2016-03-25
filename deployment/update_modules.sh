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
#  This script uses librarian-puppet-simple to populate the puppet folder with
#  upstream puppet modules.  By default, it assumes librarian-puppet-simple is
#  already available to the environment or it will fail. You can provide command
#  line options to have the script use bundler to install librarian-puppet-simple
#  if neccessary.
#
# Parameters:
#  -b - Use bundler to install librarian-puppet (optional)
#  -r - Hard git reset of librarian managed modules back to specified version (optional)
#  -p <puppet_version> - Puppet version to use with bundler (optional)
#  -h <bundle_dir> - Folder to be used as the home directory for bundler (optional)
#  -g <gem_home> - Folder to be used as the gem directory (optional)
#  -u - Run librarian update (optional)
#  -v - Verbose printing, turns on set -x (optional)
#  -? - This usage information
#
# Variables:
#  PUPPET_GEM_VERSION - the version of puppet to be pulled down by bundler
#                       Defaults to '3.4.3'
#  BUNDLE_DIR - The folder to store the bundle gems in.
#               Defaults to '/var/tmp/.bundle_home'
#  GEM_HOME - The folder to store the gems in to not require root.
#               Defaults to '/var/tmp/.gem_home'
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
  Usage: $(basename $0) [-b] [-r] [-p <puppet_version>] [-h <bundle_dir>] [-g <gem_home>] [-u] [-?]

Options:
  -b - Use bundler instead of assuming librarian-puppet is available
  -r - Hard git reset of librarian managed modules back to specified version
  -p <puppet_version> - Puppet version to use with bundler
  -h <bundle_dir> - Folder to be used as the home directory for bundler
  -g <gem_home> - Folder to be used as the gem directory
  -u - Run librarian update
  -v - Verbose printing of commands
  -? - This usage information

EOF
  exit 1
}

while getopts ":bp:l:h:vru" opt; do
  case $opt in
    b)
      USE_BUNDLER=true
      BUNDLER_EXEC="bundle exec"
      ;;
    p)
      PUPPET_GEM_VERSION=$OPTARG
      ;;
    h)
      BUNDLE_DIR=$OPTARG
      ;;
    g)
      GEM_HOME=$OPTARG
      ;;
    r)
      RESET_HARD=true
      ;;
    u)
      UPDATE=true
      ;;
    v)
      VERBOSE='--verbose'
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

DEPLOYMENT_DIR=$(cd `dirname $0` && pwd -P)
# Timeout in seconds for running puppet librarian
TIMEOUT=600
export PUPPET_GEM_VERSION=${PUPPET_GEM_VERSION:-'~>3.8'}
export BUNDLE_DIR=${BUNDLE_DIR:-'/var/tmp/.bundle_home'}
export GEM_HOME=${GEM_HOME:-'/var/tmp/.gem_home'}

# We need to be in the deployment directory to run librarian-puppet-simple
cd $DEPLOYMENT_DIR

if [ "$USE_BUNDLER" = true ]; then
  # ensure bundler is installed
  bundle --version

  # update bundler modules
  bundle update
fi

# if no timeout command, return true so we don't fail this script (LP#1510665)
TIMEOUT_CMD="$(command -v timeout) $TIMEOUT"
[ $? -eq 0 ] || TIMEOUT_CMD=true

# Check to make sure if the folder already exists, it has a .git so we can
# use git on it. If the mod folder exists, but .git doesn't then remove the mod
# folder so it can be properly installed via librarian.
for f in Puppetfile puppet/openstack_tasks/Puppetfile; do
  for MOD in $(grep "^mod" $f | tr -d '[:punct:]' | awk '{ print $2 }'); do
    MOD_DIR="${DEPLOYMENT_DIR}/puppet/${MOD}"
    if [ -d $MOD_DIR ] && [ ! -d "${MOD_DIR}/.git" ];
    then
      rm -rf "${MOD_DIR}"
    fi
  done
done

# run librarian-puppet install to populate the modules if they do not already
# exist
$TIMEOUT_CMD $BUNDLER_EXEC librarian-puppet install $VERBOSE --path=puppet

# run again to fetch openstack_tasks modules
cd $DEPLOYMENT_DIR/puppet/openstack_tasks
$TIMEOUT_CMD $BUNDLER_EXEC librarian-puppet install $VERBOSE --path=..

# run librarian-puppet update to ensure the modules are checked out to the
# correct version
if [ "$UPDATE" = true ]; then
  $TIMEOUT_CMD $BUNDLER_EXEC librarian-puppet update $VERBOSE --path=puppet

  # run again to fetch openstack_tasks modules
  cd $DEPLOYMENT_DIR/puppet/openstack_tasks
  $TIMEOUT_CMD $BUNDLER_EXEC librarian-puppet install $VERBOSE --path=..
fi

# do a hard reset on the librarian managed modules LP#1489542
if [ "$RESET_HARD" = true ]; then
  for f in Puppetfile puppet/openstack_tasks/Puppetfile; do
    for MOD in $(grep "^mod " $f | tr -d '[:punct:]' | awk '{ print $2 }'); do
      cd "${DEPLOYMENT_DIR}/puppet/${MOD}"
      git reset --hard
    done
    cd $DEPLOYMENT_DIR
  done
fi
