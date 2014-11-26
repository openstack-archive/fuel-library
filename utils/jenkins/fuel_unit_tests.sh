#!/bin/bash

# Some basic checks
if ! [ -d "$WORKSPACE" ] ; then
  echo "ERROR: WORKSPACE not found"
  exit 1
fi

if [ -z "$GERRIT_BRANCH" ] ; then
  echo "ERROR: GERRIT_BRANCH variable is empty"
  exit 1
fi

if [ -z "$PUPPET_GEM_VERSION" ] ; then
  PUPPET_GEM_VERSION='~> 3.4.0'
fi

# Check for bundle and exit if failed
bundle --version || exit 1

export GEM_HOME=$WORKSPACE/.bundled_gems

# Function that runs rake spec using bundle
function rake_spec {
  MODULE=`basename $(pwd)`
  echo "Checking module $MODULE"

  if ! [ -f Gemfile ] ; then
    echo "Gemfile not found. Skipping unit tests."
    return 0
  fi

  if ! [ -f Rakefile ] ; then
    echo "Rakefile not found. Skipping unit tests."
    return 0
  fi

  if grep -qx $MODULE $WORKSPACE/utils/jenkins/modules.disable_rspec ; then
    echo "Unit tests are disabled for $MODULE module"
    return 0
  fi

  bundle update
  bundle exec rake spec SPEC_OPTS='--format documentation'
  return $?
}

# Iterate over the changed modules and run unit tests for them
fail=0
modules=$(git diff --name-only $GERRIT_BRANCH | grep -o 'deployment/puppet/[^/]*/' | sort -u)
for mod in $modules; do
  pushd $mod &> /dev/null
  rake_spec || let fail+=1
  popd &>/dev/null
done

if test $fail -ne 0 ; then
  echo "RSpec Test FAILED: $fail modules failed RSpec tests."
  exit 1
else
  echo "RSpec Test SUCCEEDED: All modules successfully passed RSpec tests."
  exit 0
fi
