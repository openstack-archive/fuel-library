#!/bin/bash
set -e

# If we're not on master anywhere, pulling master doesn't make sense
echo Checking if all submodules are on branch master - otherwise git checkout master manually
git submodule foreach -q "git branch | grep -q '* master'"

# If we have uncommitted changes anywhere, they'll be lost.
echo Checking if submodules don\'t have uncommitted changes - otherwise commit/push manually
git submodule foreach -q 'if (git status -s | grep .); then echo You have uncommitted changes in $path, they would be lost; return 1; fi'

# If we have local unpushed changes, they'll be lost too.
echo Checking if submodules don\'t have unpushed changes - otherwise pull/push submodule manually
git submodule foreach -q 'git rev-parse master | grep -q $(git merge-base master origin/master)'

git pull 
git submodule update --init --merge

