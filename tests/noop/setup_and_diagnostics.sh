#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1

echo "Cloning the repository..."

if ! [ -d 'fuel-noop-fixtures' ]; then
  git clone 'https://github.com/openstack/fuel-noop-fixtures.git' 'fuel-noop-fixtures'
fi

if ! [ -L 'fuel-noop-fixtures/spec/hosts' ]; then
  rm -rf 'fuel-noop-fixtures/spec/hosts'
  ln -sf '../../spec/hosts' 'fuel-noop-fixtures/spec/hosts'
fi

if ! [ -f 'fuel-noop-fixtures/Gemfile.lock' ]; then
  cd 'fuel-noop-fixtures'
  bundle install
  cd '..'
fi

echo "Preparing the environment..."

./noop_tests.sh -bB -d -t -l
