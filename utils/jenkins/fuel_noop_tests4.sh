#!/bin/sh
DIR=`dirname $0`
cd $DIR || exit 1

export PUPPET_GEM_VERSION="4.5.0"
export STRICT_VARIABLES="no"

echo "Running the noop tests with Puppet version: ${PUPPET_GEM_VERSION}"
../../tests/noop/setup_and_diagnostics.sh
../../tests/noop/run_globals.sh -b $@
../../tests/noop/run_all.sh -b $@
ec="${?}"
../../tests/noop/show_failed_tasks.sh -b $@
exit "${ec}"
