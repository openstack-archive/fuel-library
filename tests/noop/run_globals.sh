#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1
echo "Running all globals tasks..."
./noop_tests.sh -g -j 'auto' -x $@
