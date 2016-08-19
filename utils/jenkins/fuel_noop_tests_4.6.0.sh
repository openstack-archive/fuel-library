#!/bin/sh
DIR=`dirname $0`
cd $DIR || exit 1

export PUPPET_GEM_VERSION="4.6.0"

# TODO: there are problems with strict variables in the l23network module. They should be fixed before strict variables can be enabled.
# TODO: https://bugs.launchpad.net/fuel/+bug/1618964
export STRICT_VARIABLES="no"

echo "Running the noop tests with Puppet version: ${PUPPET_GEM_VERSION}"
../../tests/noop/noop_tests.sh -tB
../../tests/noop/run_globals.sh -b $@
../../tests/noop/run_all.sh -b $@
../../tests/noop/show_failed_tasks.sh -b $@
