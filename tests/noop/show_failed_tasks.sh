#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1
./noop_tests.sh -r -o -O $@
