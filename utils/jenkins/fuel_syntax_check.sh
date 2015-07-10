#!/bin/bash

usage="$(basename "$0") [-h] [-m MODULE] [-a] -- runs syntax check for puppet modules, by default runs tests only for changed modules.

where:
    -h                    show this help text
    -a|--all              run syntax/linting tests for all modules
    -m|--module MODULE    run suntax/linting tests for specified module
    -p|--POSIX            run POSIX:2001 checks against bash shebangs as well
"

POSIX_CHECKS=1
while [ $# -gt 0 ] ; do
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
  -p|--POSIX)
    POSIX_CHECKS=0
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

# determine the location of this script
export SCRIPT_PATH=$(cd `dirname $0` && pwd -P)
# determine the fuel-library base directory
export FUEL_LIBRARY_PATH=$(cd "${SCRIPT_PATH}/../.." && pwd -P)
# put us in the library directory so our git and find functions work correctly
cd $FUEL_LIBRARY_PATH

if [ -z "$PUPPET_GEM_VERSION" ] ; then
  export PUPPET_GEM_VERSION='~> 3.4.0'
fi

# Check for bundle and exit if failed
bundle --version || exit 1

# Function that runs lint check for puppet manifests
check_lint() {
  MODULE=`basename $(pwd)`

  if grep -qs puppet-lint Gemfile && ! grep -qxs $MODULE $WORKSPACE/utils/jenkins/modules.disable_rake-lint ; then
    echo 'Using rake lint'
    GEM_HOME=$WORKSPACE/.bundled_gems bundle update
    GEM_HOME=$WORKSPACE/.bundled_gems bundle exec rake lint --trace
    RETURNVAL=$?
    if [ "${RETURNVAL}" -ne "0" ]; then
        echo "FAILED rake lint, return value was ${RETURNVAL}"
    fi
    return $RETURNVAL
  else
    echo 'Using puppet-lint'
    exit_code=0
    all_files=`find . -name "*.pp"`
    for x in $all_files; do
      puppet-lint \
          --no-80chars-check \
          --no-autoloader_layout-check \
          --no-nested_classes_or_defines-check \
          --no-only_variable_string-check \
          --no-2sp_soft_tabs-check \
          --no-trailing_whitespace-check \
          --no-hard_tabs-check \
          --no-class_inherits_from_params_class-check \
          --with-filename $x || exit_code=1
    done
    if [ "${exit_code}" -eq "1" ]; then
        echo "FAILED lint check for ${x}"
    fi
    return $exit_code
  fi
}

TMPFILE=$(mktemp /tmp/tmp.XXXXXXXXXX)
# Register exit trap for removing temporary files
trap 'rm -rf $TMPFILE' EXIT INT HUP

# Function for check shell scripts
check_bash() {
  bash -n "$1"
  local rc=$?
  [ $rc -ne 0 ] && return $rc

  if [ $POSIX_CHECKS -eq 0 ]; then
    cat "$1" > "${TMPFILE}"
    sed -i -e 's%^#!/bin/bash%#!/bin/sh%g' "${TMPFILE}" >/dev/null 2>&1
    /usr/bin/checkbashisms "${TMPFILE}"
  else
    /usr/bin/checkbashisms "$1"
  fi
  rc=$?
  return $rc
}

# Function that checks syntax
check_syntax() {
  exit_code=0
  all_files=`find . -name "*.pp" -o -name "*.erb" -o -name "*.sh" -o -path "*/files/*"`
  for x in $all_files; do
    case $x in
      *.pp )
        puppet parser validate --render-as s --color=false $x
        ;;
      *.erb | *.rb )
        erb -P -x -T '-' $x | ruby -c > /dev/null
        ;;
      *.sh )
        check_bash $x
        ;;
      *files/* )
        case $(file --mime --brief $x) in
          *x-shellscript*)
            check_bash $x
            ;;
          *x-ruby*)
            ruby -c $x
            ;;
          *x-python*)
            python -m py_compile $x
            ;;
          *x-perl*)
            perl -c $x
            ;;
        esac
        ;;
    esac
    RETURNVAL=$?
    if [ "${RETURNVAL}" -ne "0" ] ; then
      echo "FAILED checking ${x}, return code was ${RETURNVAL}"
      exit_code=1
    fi
  done
  return $exit_code
}

# Iterate over the changed modules and run syntax checks for them
failed_modules=""

if [ "$ALL" = '1' ] ; then
  modules=`ls -d $WORKSPACE/deployment/puppet/*`
elif [ "$MODULES" ] ; then
  modules=$MODULES
else
  git diff --name-only HEAD~ >/dev/null 2>&1 || exit 1
  modules=$(git diff --name-only HEAD~ | grep -o 'deployment/puppet/[^/]*/' | sort -u)
fi

echo "Checking modules: $modules"

for mod in $modules; do
  if [ -d $mod ] ; then
    printf "%b\n" "\nChecking $mod"
    cd $mod > /dev/null 2>&1
    check_lint || failed_modules="$failed_modules\n$mod"
    check_syntax || failed_modules="$failed_modules\n$mod"
    cd - >/dev/null 2>&1
  fi
done

if [ -z "$failed_modules" ] ; then
  printf "%b\n" "Syntax Test SUCCEEDED: no syntax errors found.\n"
  exit 0
else
  printf "%b\n" "\nSyntax Test FAILED: syntax errors found in the following modules:"
  printf "%b\n" "$failed_modules\n"
  exit 1
fi
