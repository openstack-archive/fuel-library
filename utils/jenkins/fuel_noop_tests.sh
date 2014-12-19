#!/bin/bash

if ! [ -d "$WORKSPACE" ] ; then
  echo "ERROR: WORKSPACE not found"
  exit 1
fi

if [ -z "$PUPPET_GEM_VERSION" ] ; then
  export PUPPET_GEM_VERSION='~> 3.4.0'
fi

# Check for bundle and exit if failed
#bundle --version || exit 1

export GEM_HOME=$WORKSPACE/.bundled_gems

# Iterate over astute.yaml files we have
for YAML in ./utils/noop/astute.yaml/*yaml ; do
  export astute_filename=`basename $YAML`
  echo -e "\n\n======== Running modular noop tests for $astute_filename ========\n"
  # Now iterate over tasks defined in astute.yaml and run
  # rspec tests for each (if it exists, of course)
  for task in `grep 'puppet_manifest:' $YAML | awk '{print $2}'` ; do
    dir=`echo $task | sed -e 's#.*/etc/puppet/modules/##g' -e 's#\.pp$##g' -e 's#/#_#g'`
    if [ -d "./utils/noop/$dir" ] ; then
      echo -e "\nTest found for puppet task: $task"
      pushd "./utils/noop/$dir" &>/dev/null
        #bundle update &>/dev/null
        #bundle exec rake spec SPEC_OPTS='--format documentation'
        rspec --format documentation --color
      popd &>/dev/null
    else
      echo -e "\nNo test found for puppet task: $task"
    fi
  done
done
