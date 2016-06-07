#!/bin/bash

usage="$(basename "$0") [-h] [-m MODULE] [-a] -- runs unit tests for puppet modules, by default runs tests only for changed modules.

where:
    -h                    show this help text
    -a|--all              run unit tests for all modules
    -m|--module MODULE    run unit tests for specified module
"

while [[ $# > 0 ]] ; do
  key="$1"

  case $key in
  -a|--all)
    ALL='1'
    ;;
  -m|--modules)
    MODULES="$MODULES $2"
    shift # past argument
    ;;
  -h|--help)
    echo "$usage" >&2
    exit 0
    ;;
    *)
          # unknown option
    ;;
  esac
  shift # past argument or value
done

# Some basic checks
if ! [ -d "$WORKSPACE" ] ; then
  echo "ERROR: WORKSPACE not found"
  exit 1
fi

# Check for bundle and exit if failed
bundle --version || exit 1

# Check if disabled modules list if available
test -f $WORKSPACE/utils/jenkins/modules.disable_rspec || exit 1

export GEM_HOME=$WORKSPACE/.bundled_gems

function get_module_deps {
  current_dir=`pwd`
  cd $WORKSPACE/deployment
  bundle update
  ./update_modules.sh
  cd $current_dir
}

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
  bundle exec rake spec SPEC_OPTS='--format documentation --tty --color'
  return $?
}

# Iterate over the changed modules and run unit tests for them
failed_modules=""
if [ "$ALL" == '1' ] ; then
  modules=`ls -d $WORKSPACE/deployment/puppet/*`
elif ! [ -z "$MODULES" ] ; then
  modules=$MODULES
else
  git diff --name-only HEAD~ &>/dev/null || exit 1
  modules=$(git diff --name-only HEAD~ | grep -o 'deployment/puppet/[^/]*/' | sort -u)
fi

echo "Pulling module dependencies"

get_module_deps

echo "Checking modules: $modules"

for mod in $modules; do
  if [ -d $mod ] ; then
    pushd $mod &> /dev/null
    rake_spec || failed_modules="$failed_modules\n$mod"
    popd &>/dev/null
  fi
done

if [ -z "$failed_modules" ] ; then
  echo -e "\nRSpec Tests SUCCEEDED: No errors found.\n"
  exit 0
else
  echo -e "\nRSpec Tests FAILED for the following modules:"
  echo -e "$failed_modules\n"
  exit 1
fi
