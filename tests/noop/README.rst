Fuel noop rspec tests
=====================

In order to test just execute these commands::

  export WORKSPACE=/tmp/fuel_noop_tests
  mkdir -p $WORKSPACE
  ./utils/jenkins/fuel_noop_tests.sh

In order to run specific test and/or specific astute.yaml, you can
set appropriate env variables. For example::

  export NOOP_TEST='keystone/*'
  export NOOP_YAMLS='/path/to/your/astute.yaml'
  ./utils/jenkins/fuel_noop_tests.sh

If you also want to store puppet logs in case of catalog
compilation errors, please set PUPPET_LOGS_DIR env variable::

  export PUPPET_LOGS_DIR=/tmp/puppet_error_logs

If you want to store all the delcarated File and Package resources,
please set NOOP_SAVE_RESOURCES_DIR env variable::

  export NOOP_SAVE_RESOURCES_DIR=/tmp/puppet_resources

