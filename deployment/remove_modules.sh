#!/bin/sh
# remove all external puppet modules

dir=`dirname $0`
cd "${dir}" || exit 1

./puppet_modules.rb -tv remove
