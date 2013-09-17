#!/bin/sh

ruby -v | grep -q 'ruby 1.8'

if [ $? -gt 0 ]; then
  echo "Error: you are not using ruby 1.8.*!"
  exit 1
fi

if [ -z "${WORKSPACE}" ]; then
  echo "Error! WORKSPACE is not set!"
  exit 1
fi

cd "${WORKSPACE}"

if [ $? -gt 0 ]; then
  echo "Error! Can't cd to ${WORKSPACE}"
  exit 1
fi

if [ -d 'rdoc' ]; then
  rm -rf 'rdoc'
fi

if [ ! -d "deployment/puppet" ]; then
  echo "Puppet modules not found! Something is very wrong!."
  exit 1
fi

puppet doc --verbose --mode "rdoc" --outputdir 'rdoc' --charset "utf-8" --modulepath='deployment/puppet/' --manifestdir='deployment/puppet/nailgun/examples/'

if [ $? -gt 0 ]; then
  echo "Error building RDOC pages!"
  exit 1
fi
