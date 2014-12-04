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

# Function that runs lint check for puppet manifests
function check_lint {
  MODULE=`basename $(pwd)`

  if grep -qs puppet-lint Gemfile ; then
    bundle install
    bundle exec rake lint --trace
    return $?
  else
    exit_code=0
    all_files=`find -name "*.pp"`
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
          --with-filename $x || let exit_code=1
    done
    return $exit_code
  fi
}

# Function that checks syntax
function check_syntax {
  exit_code=0
  all_files=`find -name "*.pp" -o -name "*.erb" -o -name "*.sh" -o -path "*/files/ocf/*"`
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
    if [ "$?" -ne "0" ] ; then
      exit_code=1
    fi
  done
  return $exit_code
}

# Iterate over the changed modules and run syntax checks for them
failed_modules=""
modules=$(git diff --name-only $GERRIT_BRANCH | grep -o 'deployment/puppet/[^/]*/' | sort -u)
echo remotes
git remote -v

git diff --name-only $GERRIT_BRANCH &>/dev/null || exit 1

for mod in $modules; do
  echo -e "\nChecking $mod"
  pushd $mod &> /dev/null
  check_lint || failed_modules="$failed_modules\n$mod"
  check_syntax || failed_modules="$failed_modules\n$mod"
  popd &>/dev/null
done

if [ -z "$failed_modules" ] ; then
  echo -e "Syntax Test SUCCEEDED: no syntax errors found.\n"
  exit 0
else
  echo -e "\nSyntax Test FAILED: syntax errors found in the following modules:"
  echo -e "$failed_modules\n"
  exit 1
fi
