#!/bin/sh

DIR=`dirname $0`
cd "${DIR}" || exit 1

if ! [ -d 'fuel-task-tests' ]; then
  git clone 'https://github.com/dmitryilyin/fuel-task-tests.git' 'fuel-task-tests'
fi 

if ! [ -d 'fuel-noop-fixtures' ]; then
  git clone 'https://github.com/openstack/fuel-noop-fixtures.git' 'fuel-noop-fixtures'
fi 

if ! [ -L 'fuel-task-tests/spec/hosts' ]; then
  rm -rf 'fuel-task-tests/spec/hosts'
  ln -sf '../../spec/hosts' 'fuel-task-tests/spec/hosts'
fi

cd 'fuel-task-tests' || exit 1

if ! [ -f 'Gemfile.lock' ]; then
  bundle install
fi

export SPEC_ROOT_DIR='.'
export SPEC_DEPLOYMENT_DIR='../../../deployment'
export SPEC_HIERA_DIR='../fuel-noop-fixtures/hiera'
export SPEC_FACTS_DIR='../fuel-noop-fixtures/facts'
export SPEC_SPEC_DIR='spec/hosts'
export SPEC_TASK_DIR='../../../deployment/puppet/osnailyfacter/modular'
export SPEC_MODULE_PATH='../../../deployment/puppet'

./noop_tests.rb $@
