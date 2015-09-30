#!/bin/bash

DIR=`dirname $0`

echo 'Ruby version:'
ruby --version

"${DIR}/fuel_validate_puppetfile.rb" ${@}

