#!/bin/sh
DIR=`dirname $0`
cd $DIR || exit 1
../../tests/noop/run_tests.sh $@
