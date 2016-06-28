#!/bin/bash
set -eux
DIR=`dirname $0`
cd "${DIR}" || exit 1

REPO_URL=${NOOP_FIXTURES_REPO_URL:-'https://github.com/openstack/fuel-noop-fixtures.git'}
clone_fixtures_repo() {
  if ! [ -d 'fuel-noop-fixtures' ]; then
    echo "Cloning the repository..."
    git clone "${REPO_URL}" 'fuel-noop-fixtures'
  fi
}

link_yaql_fixtures() {
  if ! [ -L 'fixtures' ]; then
    echo "Linking repo fixtures to the local FS..."
    ln -sf 'fuel-noop-fixtures/yaql' 'fixtures'
  fi
}

check_tox() {
  type tox >/dev/null 2>&1 || { echo >&2 "Tox is required to be installed to run tests."; exit 1; }
}

run_tox() {
  echo "Run tests..."
  tox
}

check_tox
clone_fixtures_repo
link_yaql_fixtures
run_tox


