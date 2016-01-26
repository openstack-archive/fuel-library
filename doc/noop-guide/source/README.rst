.. _fuel_noop_howto:

Fuel noop rspec tests
=====================

Using the fuel_noop_tests.sh wrapper util
-----------------------------------------

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

Using the fuel_noop_tests.rb util directly
------------------------------------------

The tool provides an advanced functionality.
Use the -h key to get the help.

.. _fuel_noop_catalogs_diff:

Deployment data layer checks
============================

Below are typical use cases for the `fuel_noop_tests.rb`
tool to perform a data layer checks of a change-set
(a patch) against the committed state of the data layer.

Ruby and puppet version to be used (optional)
---------------------------------------------

::

  rvm use ruby-1.9.3-p545
  PUPPET_GEM_VERSION=3.4.0
  PUPPET_VERSION=3.4.0

Initial data templates generation (preparing the committed state)
-----------------------------------------------------------------

Generate *all* data templates of all specs of all deployment scenarios
making a reset [#]_ & update of librarian puppet before

::

  ./utils/jenkins/fuel_noop_tests.rb -Q -b -r -u

.. [#] Use `./deployment/remove_modules.sh` to forcibly remove external
  modules in order to re-fetch them by the `-r` parameter.

the same but only for a particular ap-proxi spec
(use -S to get the full list)

::

  ./utils/jenkins/fuel_noop_tests.rb -Q -b -s api-proxy/api-proxy_spec.rb


the same but only for the particular ap-proxi spec and the particular
deployment scenario (use -Y to get the full list)

::

  ./utils/jenkins/fuel_noop_tests.rb -Q -b -s api-proxy/api-proxy_spec.rb \
  -y neut_vlan.compute.ssl.yaml

Running the data regression checks against a change-set under test
------------------------------------------------------------------

Run checks against the committed state of the data templates and save
failed cases as a replay file. Note that this normally shall be done
by a non-voting CI gate to show data chages being made to reviewers (TODO).

::

  ./utils/jenkins/fuel_noop_tests.rb -q -b -A replay.log

Re-run the data regression checks against the committed state of the data
templates using the replay file and skipping all of the globals templates
being re-generated again (a handy shourtcut for the test time)

::

  ./utils/jenkins/fuel_noop_tests.rb -q -b -g -a replay.log

Confirming the data changes made to became a new committed state
----------------------------------------------------------------

This shall be done automatically for each patch being committed to the
fuel-library repo. The catalogs shall be regenerated and committed to the
fuel-noop-fixtures repo by a Zuul hook configured in the OpenStack infra
(TODO).
