.. _fuel_noop_fixtures:

Fuel noop fixtures
==================

There is a separate fuel-noop-fixtures_ repository to store
all of the fixtures required for the noop tests execution.
These will be automatically fetched for each run of noop tests
to the
``./tests/noop/fuel-noop-fixtures``
directory.
(TODO describe fixtures for catalogs diff when ready for use)

.. _fuel-noop-fixtures: https://github.com/openstack/fuel-noop-fixtures

Developers of integration noop tests shall submit changes to
fixtures like `hiera` and `facts` templates to that repository instead
of the main fuel-library repositroy.

To get the list of available `hiera` and `facts` fixtures, one may use the commands ::

  ./utils/jenkins/fuel_noop_tests.rb -Y
  ./utils/jenkins/fuel_noop_tests.rb -F
