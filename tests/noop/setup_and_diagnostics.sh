#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1

REPO_URL=${NOOP_FIXTURES_REPO_URL:-'https://git.openstack.org/openstack/fuel-noop-fixtures'}
BRANCH=${NOOP_FIXTURES_BRANCH:-'refs/changes/48/312948/3'}
GERRIT_URL=${NOOP_FIXTURES_GERRIT_URL:-'https://review.openstack.org/openstack/fuel-noop-fixtures'}
GERRIT_COMMIT=${NOOP_FIXTURES_GERRIT_COMMIT:-'none'}

clone_fixtures_repo() {
  if ! [ -d 'fuel-noop-fixtures' ]; then
    echo "Cloning the repository..."
    git clone "${REPO_URL}" 'fuel-noop-fixtures'
  fi
}

update_fixtures_repo() {
  echo "Updating the repository..."
  cd 'fuel-noop-fixtures' || return 1
  git fetch origin $BRANCH
  git checkout FETCH_HEAD
  git clean -fd
  if [ "$GERRIT_COMMIT" != "none" ]; then
    for patch in $GERRIT_COMMIT ; do
      git fetch $GERRIT_URL $patch && git cherry-pick FETCH_HEAD || exit 1
    done
  fi
  cd '..'
}

link_specs_to_fixtures() {
  if ! [ -L 'fuel-noop-fixtures/spec/hosts' ]; then
    echo "Linking specs top the repository..."
    rm -rf 'fuel-noop-fixtures/spec/hosts'
    ln -sf '../../spec/hosts' 'fuel-noop-fixtures/spec/hosts'
  fi
}

prepare_environment() {
  echo "Preparing the environment..."
  ./noop_tests.sh -bB -d -t -l -L
}

clone_fixtures_repo
update_fixtures_repo
link_specs_to_fixtures
prepare_environment
