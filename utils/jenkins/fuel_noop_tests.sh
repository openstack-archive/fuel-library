#!/bin/bash

DIR=`dirname $0`

echo 'Ruby version:'
ruby --version

"${DIR}/fuel_noop_tests.rb" -b -d -p -u -O -m ${@}

