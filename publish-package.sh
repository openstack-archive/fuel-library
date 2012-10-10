#!/bin/bash

if [ ! $# == 1 ]; then

  echo "Usage: $0 <fuel-package-name.tar.gz>"
  
  lines=`ls fuel-*.tar.gz 2> /dev/null`  
  if [[ ! $lines ]]; then 
      echo "No archives available for publishing"
  else
      echo "Available archives for publishing:"
      for line in $lines; do echo "  * $line (run \"$0 $line\")"; done
  fi  
  
  exit

fi

package_file="$1"

if [ ! -f $package_file ]; then
    echo "File $package_file not found!"
    exit
fi

#
# publish package to http://download.mirantis.com/fuel-releases/
#
rsync -v $package_file rsync://repo.srt.mirantis.net:/repo/fuel-releases/$package_file

