#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1
echo "Running all spec tasks..."
./noop_tests.sh -j 'auto' -x $@
