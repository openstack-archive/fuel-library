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
#  This script uses bundler and librarian-puppet to populate the puppet folder
#  with upstream puppet modules.
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
#        same name.
#
# Author: Alex Schultz <aschultz@mirantis.com>
#
###############################################################################
set -ex

DEPLOYMENT_DIR=`dirname $0`
PUPPET_GEM_VERSION=${PUPPET_GEM_VERSION:-'3.4.3'}
LIBRARIAN_TMP=${LIBRARIAN_TMP:-'/var/tmp/.librarian_tmp'}
BUNDLE_DIR=${BUNDLE_DIR:-'/var/tmp/.bundle_home'}

# We need to be in the deployment directory to run librarian-puppet
cd $DEPLOYMENT_DIR

# ensure bundler is installed
bundle --version

# update bundler modules
bundle update

# set the temp directory for global librarian config
bundle exec librarian-puppet config --global tmp $LIBRARIAN_TMP

# run librarian-puppet update to populate the modules
bundle exec librarian-puppet update

# run librarian-puppet show to list the modules being managed and their versions
bundle exec librarian-puppet show
