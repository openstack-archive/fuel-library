#!/bin/bash

name=fuel-library
version=6.1
prev_version=6.0
amount_of_commits=`git rev-list ${prev_version}..HEAD --count`
short_commit=`git rev-parse --short HEAD`
builddate=`date +%Y%m%d`
release="${amount_of_commits}.${builddate}git${short_commit}"
archname=${name}-${version}-${version}-${release}
sourcedir=~/rpmbuild/SOURCES
gitdir=$(pwd)

git archive --worktree-attributes --format=tar HEAD | bzip2 -9 > ${sourcedir}/${archname}.tar.bz2
PKG_VERSION=${version} PKG_RELEASE=${release} rpmbuild -ba specs/fuel-library.spec

