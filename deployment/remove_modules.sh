#!/bin/bash
# remove all external puppet modules

DEPLOYMENT_DIR=$(cd `dirname $0` && pwd -P)
PUPPET_FILES=$(find $DEPLOYMENT_DIR -name Puppetfile)

for f in $PUPPET_FILES; do
  cat $f | grep "^mod '" | awk -F "'" '{ print $2 }' | while read module; do
    if [ -d "${DEPLOYMENT_DIR}/puppet/${module}" ]; then
      echo "Remove: puppet/${module}"
      rm -rf "${DEPLOYMENT_DIR}/puppet/${module}"
    fi
  done
  rm -f "${f}.lock"
done
