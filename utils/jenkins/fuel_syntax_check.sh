#!/bin/bash

set -e

#TODO: Run these in parallel - we have 4 cores.
#TODO: Control the environment (through the config dir?).
#      We want to parse for all environments.
#      Is this being done, contrary to puppet report?
#TODO: Even with --ignoreimport, some may be pulling in others,
#      meaning we're checking multiple times.

#all_files=`find -name "*.pp" -o -name "*.erb" -o -name "*.sh" -o -name "*.rb"`

if [ -z "$*" ]; then
  ruby_files=`find -type f -print0 | xargs -0 file -i | grep -i ruby | awk -F: '{ print $1 }'`
  all_files="${ruby_files} `find -name "*.pp" -o -name "*.erb" -o -name "*.sh"`"
else
  all_files="$*"
fi

num_files=`echo $all_files | wc -w`

if test $num_files -eq "0" ; then
  echo "WARNING: no .sh, .pp, .rb or .erb files found"
  exit 0
fi

echo "Checking $num_files files for syntax errors."
echo "Puppet version is: `puppet --version`"

for x in $all_files; do
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
        --no-class_inherits_from_params_class-check \
        --with-filename $x

    puppet parser validate --render-as s --color=false $x
    ;;
  *.erb | *.rb )
    erb -P -x -T '-' $x | ruby -c > /dev/null
    ;;
  *.sh )
    bash -n $x
    ;;
  esac
done

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
