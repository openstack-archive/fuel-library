#!/bin/sh

dir=`dirname $0`
cd "${dir}" || exit 1

cat Puppetfile | grep "^mod '" | awk -F "'" '{ print $2 }' | while read module; do
  if [ -d "puppet/${module}" ]; then
    echo "Remove: puppet/${module}"
    rm -rf "puppet/${module}"
  fi
done
