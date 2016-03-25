#!/bin/sh
# remove all external puppet modules

dir=`dirname $0`
cd "${dir}" || exit 1

for f in Puppetfile puppet/openstack_tasks/Puppetfile; do
  cat $f | grep "^mod '" | awk -F "'" '{ print $2 }' | while read module; do
    if [ -d "puppet/${module}" ]; then
      echo "Remove: puppet/${module}"
      rm -rf "puppet/${module}"
    fi
  done
done
rm -f 'Puppetfile.lock'
