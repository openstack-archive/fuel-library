#!/bin/sh
DIR=`dirname $0`
cd $DIR || exit 1

./fuel_noop_tests_3.8.7.sh
if [ $? -gt 0 ]; then
  echo "Noop tests for Puppet 3.8.7 have failed!"
  exit 1
fi

#./fuel_noop_tests_4.5.0.sh
#if [ $? -gt 0 ]; then
#  echo "Noop tests for Puppet 4.5.0 have failed!"
#  exit 1
#fi
