#!/bin/bash

git checkout master

set -e

# If we're not on master anywhere, pushing master will do nothing
echo Checking if all submodules are on branch master - otherwise git checkout master manually
if ! git submodule foreach -q "git branch | grep -q '* master'"
then
    echo The submodule above is not on branch master. ./push-all.sh only works with branch master.
    echo If you\'re in a \"topic branch\", just do \"git checkout master\" there.
    echo If you\'re on a \"\(no branch\)\" because you forgot to checkout master previously, 
    echo then port your changes to branch master:
    echo "    git checkout master"
    echo "    git merge ORIG_HEAD"
    echo Then rerun ./push-all.sh.
    exit 1
fi

echo Checking for uncommitted changes in submodules
if ! git submodule foreach -q 'if (git status -s | grep .); then echo You have uncommitted changes in $path; return 1; fi'
then
    echo The submodule above has uncommitted changes.
    echo Please commit them and rerun ./push-all.sh
    exit 1
fi

echo Checking if push will not conflict in submodules
if ! git submodule foreach -q 'echo $path; (git rev-parse origin/master | grep -q $(git rev-parse master)) || git push -q --dry-run origin master'
then
    echo The submodule above will conflict during push.
    echo Please run ./pull-all.sh, resolve the conflicts and then rerun ./push-all.sh.
    exit 1
fi

changed=0
subrepos=""
for subrepo in `git submodule status | grep '^+' | awk '{print $2}'`
do
    subrepos="$subrepo $subrepos"
    changed=1
    pushd $subrepo
        git push origin master
    popd
done
if [ "$changed" == "1" ]
then
    git commit -m "Updated submodules: $subrepos" $subrepos
fi
git push origin master
