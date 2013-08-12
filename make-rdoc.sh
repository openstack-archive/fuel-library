#!/bin/sh

ruby -v | grep -q 'ruby 1.8'

if [ $? -gt 0 ]; then
  echo "Error: you are not using ruby 1.8.*!"
  exit 1
fi

file="${0}"
dir=`dirname "${file}"`
cd "${dir}" || exit 1

if [ -d 'rdoc' ]; then
  rm -rf 'rdoc'
fi

puppet doc --mode "rdoc" --outputdir 'rdoc' --charset "utf-8" --modulepath='deployment/puppet/' --manifestdir='deployment/puppet/nailgun/examples/'

if [ $? -gt 0 ]; then
  exit 1
fi

if [ "`uname`" = 'Darwin' ]; then
  open 'rdoc/index.html'
elif [ "`uname`" = 'Linux' ]; then
  xdg-open 'rdoc/index.html'
else
  exit 1
fi
