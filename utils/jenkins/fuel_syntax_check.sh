# export
# exit 1
# ~/check_puppet_syntax.sh
set +x

set -e
#set -u

fail=0
#TODO: Run these in parallel - we have 4 cores.
#TODO: Control the environment (through the config dir?).
#      We want to parse for all environments.
#      Is this being done, contrary to puppet report?
#TODO: Even with --ignoreimport, some may be pulling in others,
#      meaning we're checking multiple times.
all_files=`find -name "*.pp" -o -name "*.erb" -o -name "*.rb" -o -name "*.sh"`
num_files=`echo $all_files | wc -w`
if test $num_files -eq "0" ; then
  echo "WARNING: no .sh, .pp, .rb or .erb files found"
  exit 0
fi
echo "Checking $num_files files for syntax errors."
echo "Puppet version is: `puppet --version`"

for x in $all_files; do
  rc=0
  set +e
  case $x in
  *.pp )
    puppet-lint \
        --no-80chars-check \
        --no-autoloader_layout-check \
        --no-nested_classes_or_defines-check \
        --no-only_variable_string-check \
        --no-2sp_soft_tabs-check \
        --no-trailing_whitespace-check \
        --no-hard_tabs-check \
        --with-filename $x

    rc=$?
    # Set us up to bail if we receive any syntax errors
    if test $rc -eq 0
    then
        puppet parser validate --render-as s --ignoreimport --color=false $x
        rc=$?
    fi
    ;;
  *.erb | *.rb )
    erb -P -x -T '-' $x | ruby -c > /dev/null
    rc=$?
    ;;
  *.sh )
    bash -n $x
    rc=$?
    ;;
  esac
#  rc=$?
  set -e
  if test $rc -ne 0
  then
    fail=1
    echo "ERROR in $x (see above)"
  fi
done

if test $fail -ne 0
then
#  curl -i -u paly-ch -d '{"body":":-1: Verification FAILED: at least one file failed syntax check."}' https://api.github.com/repos/Mirantis/fuel/issues/${ghprbPullId}/comments
  echo "Verification FAILED: at least one file failed syntax check."
  exit $fail
else
  echo "Verification SUCCEEDED."
  #echo "Verification SUCCESS: Running SPECs."
  #FIXME(mihgen): We don't run specs at the moment
  #exit 0
  if [ "$1" = "-u" ];
  then
    all_files=`find -iname "rakefile"`
    num_files=`echo $all_files | wc -w`
    if test $num_files -eq "0" ; then
      echo "WARNING: no Rakefile files found"
      exit 0
    fi
    echo "Will run $num_files RSpec tests."
    echo "Rake version is: `rake --version`"

    for file in $all_files; do
      d=`dirname $file`
      dn=`basename $d`
      cd $d
      rc=0
      echo "RSpec-ing $dn"
      set +e
      rake spec
      rc=$?
      set -e
      if test $rc -ne 0 ; then
        fail=1
        echo "ERROR in $dn (see above)"
      fi
      cd ${WORKSPACE}
    done

    if test $fail -ne 0 ; then
      echo "RSpec Test FAILED: at least one module failed RSpec tests."
    else
      echo "RSpec Test SUCCEEDED: All modules successfully passed RSpec tests."
    fi
  fi
fi
exit $fail
