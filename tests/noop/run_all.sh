#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1
echo "Running all spec tasks..."
procs=$(grep -c processor /proc/cpuinfo)
concur=${USER_SPECIFIED_JOBS:-$procs}
./noop_tests.sh -j $concur -x $@
