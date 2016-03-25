#!/bin/bash
# remove all external puppet modules

dir=`dirname $0`
cd "${dir}" || exit 1

PUPPET_FILES=$(find $dir -name Puppetfile)

for f in $PUPPET_FILES; do
  cat $f | grep "^mod '" | awk -F "'" '{ print $2 }' | while read module; do
    if [ -d "puppet/${module}" ]; then
      echo "Remove: puppet/${module}"
      rm -rf "puppet/${module}"
    fi
  done
done
rm -f 'Puppetfile.lock'
