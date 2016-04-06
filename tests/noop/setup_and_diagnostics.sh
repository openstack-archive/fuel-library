#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1

REPO_URL='https://github.com/openstack/fuel-noop-fixtures.git'

clone_fixtures_repo() {
  if ! [ -d 'fuel-noop-fixtures' ]; then
    echo "Cloning the repository..."
    git clone "${REPO_URL}" 'fuel-noop-fixtures'
  fi
}

update_fixtures_repo() {
  echo "Updating the repository..."
  cd 'fuel-noop-fixtures' || return 1
  git fetch --all
  git clean -fd
  git reset --hard 'origin/stable/mitaka'
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
