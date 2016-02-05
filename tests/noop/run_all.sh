#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1
./noop_tests.sh -j 20 $@
