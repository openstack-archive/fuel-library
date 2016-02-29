#!/bin/sh
# remove all external puppet modules

dir=`dirname $0`
cd "${dir}" || exit 1

tar -czpvf puppet_modules.tgz `cat Puppetfile | grep "^mod '" | awk -F "'" '{ print "puppet/"$2 }'` 
