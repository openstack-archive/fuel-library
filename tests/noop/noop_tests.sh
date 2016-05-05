#!/bin/sh

DIR=`dirname $0`
cd "${DIR}" || exit 1

cd 'fuel-noop-fixtures' || exit 1

export SPEC_ROOT_DIR='.'
export SPEC_DEPLOYMENT_DIR='../../../deployment'
export SPEC_HIERA_DIR='hiera'
export SPEC_FACTS_DIR='facts'
export SPEC_SPEC_DIR='spec/hosts'
export SPEC_TASK_DIR='../../../deployment/puppet/osnailyfacter/modular'
export SPEC_MODULE_PATH='../../../deployment/puppet'

if [ -z "${PUPPET_GEM_VERSION}" ]; then
  export PUPPET_GEM_VERSION='4.5.0'
fi

./noop_tests.rb $@
