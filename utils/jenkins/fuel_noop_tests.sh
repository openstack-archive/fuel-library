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

failed_yamls=""

# Iterate over astute.yaml files we have and run tests
for YAML in ./utils/noop/astute.yaml/*yaml ; do
  echo "${YAML}" | grep -q 'globals_yaml_for_'
  if [ $? -eq 0 ]; then
    continue
  fi
  export astute_filename=`basename $YAML`
  echo -e "\n\n======== Running modular noop tests for $astute_filename ========\n"
  pushd ./utils/noop
  echo "Starting test for YAML '${astute_filename} at directory '`pwd`'"
  bundle exec rake spec || failed_yamls="$failed_yamls\n$astute_filename"
  popd
done

# Report and exit
if [ -z "$failed_yamls" ] ; then
  echo -e "\nRSpec Noop Tests SUCCEEDED: No errors found.\n"
  exit 0
else
  echo -e "\nRSpec Noop Tests FAILED for the following astute.yaml files:"
  echo -e "$failed_yamls\n"
  exit 1
fi

