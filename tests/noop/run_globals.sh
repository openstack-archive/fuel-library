#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1
echo "Runing all globals tasks..."
./noop_tests.sh -g -d -j 24 -x $@
