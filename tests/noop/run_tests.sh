#!/bin/sh

setup() {
  if ! [ -d 'fuel-task-tests' ]; then
    git clone 'https://github.com/dmitryilyin/fuel-task-tests.git' 'fuel-task-tests'
  fi 
  if ! [ -f 'lib' ]; then
    ln -sf 'fuel-task-tests/lib' 'lib'
  fi
  ln -sf '../fuel-task-tests/spec/spec_helper.rb' 'spec' 
  ln -sf '../fuel-task-tests/spec/shared-examples.rb' 'spec' 
  ln -sf 'fuel-task-tests/Gemfile' 'Gemfile'
}

DIR=`dirname $0`
cd "${DIR}" || exit 1

setup

export SPEC_ROOT_DIR='.'
export SPEC_DEPLOYMENT_DIR='../../deployment'
export SPEC_HIERA_DIR='hiera'
export SPEC_FACTS_DIR='facts'
export SPEC_SPEC_DIR='spec/hosts'
export SPEC_TASK_DIR='../../deployment/puppet/osnailyfacter/modular'
export SPEC_MODULE_PATH='../../deployment/puppet'

fuel-task-tests/noop_tests.rb $@
