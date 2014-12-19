#!/bin/bash

# Some basic checks
if ! [ -d "$WORKSPACE" ] ; then
  echo "ERROR: WORKSPACE not found"
  exit 1
fi

if [ -z "$PUPPET_GEM_VERSION" ] ; then
  export PUPPET_GEM_VERSION='~> 3.4.0'
fi

# Check for bundle and exit if failed
bundle --version || exit 1

# Check if disabled modules list if available
test -f $WORKSPACE/utils/jenkins/modules.disable_rspec || exit 1

export GEM_HOME=$WORKSPACE/.bundled_gems

# Function that runs rake spec using bundle
function rake_spec {
  MODULE=`basename $(pwd)`
  echo -e "\nChecking module $MODULE"

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
failed_modules=""
modules=$(git diff --name-only HEAD~ | grep -o 'deployment/puppet/[^/]*/' | sort -u)
git diff --name-only HEAD~ &>/dev/null || exit 1

for mod in $modules; do
  pushd $mod &> /dev/null
  rake_spec || failed_modules="$failed_modules\n$mod"
  popd &>/dev/null
done

if [ -z "$failed_modules" ] ; then
  echo -e "RSpec Test SUCCEEDED: All modules successfully passed RSpec tests.\n"
  exit 0
else
  echo -e "\nRSpec RSpec tests failed for the following modules:"
  echo -e "$failed_modules\n"
  exit 1
fi
