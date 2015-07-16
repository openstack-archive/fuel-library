#!/bin/bash

set -ex

DEPLOYMENT_DIR=`dirname $0`
PUPPET_GEM_VERSION=${PUPPET_GEM_VERSION:-'3.4.3'}
LIBRARIAN_TMP=${LIBRARIAN_TMP:-'/var/tmp/.librarian_tmp'}
BUNDLE_DIR=${BUNDLE_DIR:-'/var/tmp/.bundle_home'}

cd $DEPLOYMENT_DIR
# check if bundler is installed
bundle --version

# update bundler modules
bundle update

# set the temp directory for global librarian config 
bundle exec librarian-puppet config --global tmp $LIBRARIAN_TMP

# run librarian-puppet update to populate the modules
bundle exec librarian-puppet update

# run librarian-puppet show to list the modules being managed and their versions
bundle exec librarian-puppet show
