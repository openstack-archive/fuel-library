#!/bin/bash

DIR=`dirname $0`
"${DIR}/fuel_noop_tests.rb" -b -d -u -m ${@}

