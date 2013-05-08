#!/bin/bash
set -e

if [ ! $# == 1 ]; then

  echo "Usage: $0 <release-tag>"
  echo "Available release tags from git:"
  for line in `git tag -l`; do echo "  * $line (run \"$0 $line\")"; done
  echo "In order to create a new release tag, use:"
  echo "  * git tag -a <release-tag> -m \"message\""
  echo "  * git push --tags"
  exit

fi

# determine release tag
tag="$1"
build_dir="fuel-$tag"

# create directory
rm -rf $build_dir
mkdir $build_dir

# checkout fuel into it
git clone git@github.com:Mirantis/fuel.git $build_dir
cd $build_dir
git checkout $tag

# capture commit id
commit=`git rev-parse HEAD`

# remove git tracking
rm -rf `find . -name ".git*"`

# generate release version
echo $tag > release.version
echo $commit > release.commit

# build documentation
cd docs
make html
cd ..

# copy it to the new directory
rm -rf documentation
mkdir documentation
cp -R docs/_build/html/* documentation/

# create archive
cd ..
tar -czf $build_dir.tar.gz "$build_dir/deployment/" "$build_dir/documentation/" "$build_dir/release.commit" "$build_dir/release.version"

# remove build directory
rm -rf $build_dir

