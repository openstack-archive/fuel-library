#!/bin/bash

if ! [ -d "$WORKSPACE" ] ; then
  echo "ERROR: WORKSPACE not found"
  exit 1
fi

if [ -z "$PUPPET_GEM_VERSION" ] ; then
  export PUPPET_GEM_VERSION='~> 3.4.0'
fi

# Check for bundle and exit if failed
bundle --version || exit 1

export GEM_HOME=$WORKSPACE/.bundled_gems

# Prepare gems
pushd ./utils/noop
bundle update
popd

# Iterate over astute.yaml files we have
for YAML in ./utils/noop/astute.yaml/*yaml ; do
  echo "${YAML}" | grep -q 'globals_yaml_for_'
  if [ $? -eq 0 ]; then
    continue
  fi
  export astute_filename=`basename $YAML`
  echo -e "\n\n======== Running modular noop tests for $astute_filename ========\n"
  pushd ./utils/noop
  echo "Starting test for YAML '${astute_filename} at directory '`pwd`'"
  bundle exec rake spec
  popd
done
