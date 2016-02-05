#!/bin/sh

DIR=`dirname $0`
cd "${DIR}" || exit 1

if ! [ -d 'fuel-noop-fixtures' ]; then
  git clone 'https://github.com/openstack/fuel-noop-fixtures.git' 'fuel-noop-fixtures'
fi 

if ! [ -L 'fuel-noop-fixtures/spec/hosts' ]; then
  rm -rf 'fuel-noop-fixtures/spec/hosts'
  ln -sf '../../spec/hosts' 'fuel-noop-fixtures/spec/hosts'
fi

cd 'fuel-noop-fixtures' || exit 1

if ! [ -f 'Gemfile.lock' ]; then
  bundle install
fi

export SPEC_ROOT_DIR='.'
export SPEC_DEPLOYMENT_DIR='../../../deployment'
export SPEC_HIERA_DIR='hiera'
export SPEC_FACTS_DIR='facts'
export SPEC_SPEC_DIR='spec/hosts'
export SPEC_TASK_DIR='../../../deployment/puppet/osnailyfacter/modular'
export SPEC_MODULE_PATH='../../../deployment/puppet'

./noop_tests.rb $@
