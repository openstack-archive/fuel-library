#!/bin/sh
DIR=`dirname $0`
cd $DIR || exit 1

./fuel_noop_tests3.sh
if [ $? -gt 0 ]; then
  echo "Noop tests for Puppet 3 have failed!"
  exit 1
fi

#./fuel_noop_tests4.sh
#if [ $? -gt 0 ]; then
#  echo "Noop tests for Puppet 4 have failed!"
#  exit 1
#fi
