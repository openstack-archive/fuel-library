#!/bin/bash
usage="$(basename "$0") [-h] [-m MODULE] [-a] -- runs syntax check for puppet modules, by default runs tests only for changed modules.

where:
    -h                    show this help text
    -a|--all              run syntax/linting tests for all modules
    -m|--module MODULE    run suntax/linting tests for specified module
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

# determine the location of this script
export SCRIPT_PATH=$(cd `dirname $0` && pwd -P)
# determine the fuel-library base directory
export FUEL_LIBRARY_PATH=$(cd "${SCRIPT_PATH}/../.." && pwd -P)
# put us in the library directory so our git and find functions work correctly
cd $FUEL_LIBRARY_PATH

# Check for bundle and exit if failed
bundle --version || exit 1

# Function that runs lint check for puppet manifests
function check_lint {
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
          --no-only_variable_string-check \
          --no-2sp_soft_tabs-check \
          --no-trailing_whitespace-check \
          --no-hard_tabs-check \
          --no-class_inherits_from_params_class-check \
          --with-filename $x || let exit_code=1
    done
    if [ "${exit_code}" -eq "1" ]; then
        echo "FAILED lint check for ${x}"
    fi
    return $exit_code
  fi
}

# Function that checks syntax
function check_syntax {
  exit_code=0
  all_files=`find . -name "*.pp" -o -name "*.erb" -o -name "*.sh" -o -name '*.yaml' -o -name '*.yml' -o -path "*/files/ocf/*"`
  for x in $all_files; do
    case $x in
      *.pp )
        puppet parser validate --render-as s --color=false $x
        ;;
      *.erb | *.rb )
        erb -P -x -T '-' $x | ruby -c > /dev/null
        ;;
      *.sh )
        bash -n $x
        ;;
      *.yaml | *.yml )
        ruby -ryaml -e "
        puts 'Checking YAML file: ${x}'
        YAML.load_file('${x}')
        exit(0)"
        ;;
      *files/ocf/* )
        case $(file --mime --brief $x) in
          *x-shellscript*)
            bash -n $x
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

if [ "$ALL" == '1' ] ; then
  modules=`ls -d $WORKSPACE/deployment/puppet/*`
elif ! [ -z "$MODULES" ] ; then
  modules=$MODULES
else
  git diff --name-only HEAD~ &>/dev/null || exit 1
  modules=$(git diff --name-only HEAD~ | grep -o 'deployment/puppet/[^/]*/' | sort -u)
fi

echo "Checking modules: $modules"

for mod in $modules; do
  if [ -d $mod ] ; then
    echo -e "\nChecking $mod"
    pushd $mod &> /dev/null
    check_lint || failed_modules="$failed_modules\n$mod"
    check_syntax || failed_modules="$failed_modules\n$mod"
    popd &>/dev/null
  fi
done

if [ -z "$failed_modules" ] ; then
  echo -e "Syntax Test SUCCEEDED: no syntax errors found.\n"
  exit 0
else
  echo -e "\nSyntax Test FAILED: syntax errors found in the following modules:"
  echo -e "$failed_modules\n"
  exit 1
fi
