#!/bin/sh
DIR=`dirname $0`
cd $DIR || exit 1

export PUPPET_GEM_VERSION="3.8.7"
echo "Running the noop tests with Puppet version: ${PUPPET_GEM_VERSION}"
../../tests/noop/noop_tests.sh -tB
../../tests/noop/run_globals.sh -b $@
../../tests/noop/run_all.sh -b $@
../../tests/noop/show_failed_tasks.sh -b $@
