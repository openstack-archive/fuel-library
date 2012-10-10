#!/bin/bash
set -e

if [ ! $# == 1 ]; then

  echo "Usage: $0 <fuel-package-name.tar.gz>"
  echo "Available archives for publishing:"
  for line in `ls fuel-*.tar.gz`; do echo "  * $line (run \"$0 $line\")"; done
  exit

fi

package_file="$1"

if [ ! -f $package_file ];
then
    echo "File $package_file not found!"
    exit
fi

rsync -v $package_file rsync://repo.srt.mirantis.net:/repo/fuel-releases/$package_file

