#!/bin/sh
DIR=`dirname $0`
cd $DIR || exit 1

../../tests/noop/setup_and_diagnostics.sh $@
if [ $? -gt 0 ]; then
  echo "Noop tests setup have failed!"
  exit 1
fi
./fuel_noop_tests_3.8.7.sh
if [ $? -gt 0 ]; then
  echo "Noop tests for Puppet 3.8.7 have failed!"
  exit 1
fi
./fuel_noop_tests_4.6.0.sh
if [ $? -gt 0 ]; then
  echo "Noop tests for Puppet 4.6.0 have failed!"
  exit 1
fi
