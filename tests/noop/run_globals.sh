#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1
./noop_tests.sh -g --spec_status -d -j 20 $@
