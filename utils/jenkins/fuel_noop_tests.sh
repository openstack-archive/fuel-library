#!/bin/sh
DIR=`dirname $0`
cd $DIR || exit 1

../../tests/noop/setup_and_diagnostics.sh $@
../../tests/noop/run_globals.sh -b $@
../../tests/noop/run_all.sh -b $@
../../tests/noop/show_failed_tasks.sh -b $@
