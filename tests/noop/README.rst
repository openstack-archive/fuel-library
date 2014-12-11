In order to test just execute these commands:

  export WORKSPACE=/tmp/fuel_noop_tests
  mkdir -p $WORKSPACE
  ./utils/jenkins/fuel_noop_tests.sh

If you also want to store puppet logs in case of catalog
compilation errors, please set PUPPET_LOGS_DIR env variable:

  export PUPPET_LOGS_DIR=/tmp/puppet_error_logs


