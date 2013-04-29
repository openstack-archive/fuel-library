::

Grizzly CI job example
==============================================

This is an example of grizzly job for lab deployment and TEMPEST run against it.

Quickstart
----------

To create CI job using grizzly tempest and grizzly simple fuel forks...
To deploy lab ...
To run TEMPEST ...
Shell commands for CI job:

. ~/work/venv/bin/activate
export ENV_NAME=$JOB_NAME
export CREATE_SNAPSHOTS=false
# Tempest dirty-hack for public pools
#export PUBLIC_POOL=172.18.91.0/24:26
export PUBLIC_POOL=10.107.0.0/16:24
if [ "$test_name" == "TEMPEST" ]; then
  # need protect 
  pushd fuel
  pip install python-keystoneclient==0.2.3
  pip install python-quantumclient==2.2.1 
  # Add || true for tempest reentrable
  PYTHONPATH=. python fuel_test/prepare.py || true
  popd
  #
  deactivate
  cp tempest.conf $WORKSPACE/tempest/etc/
  virtualenv venv --no-site-packages
  . venv/bin/activate
  pip install -r tempest/tools/pip-requires
  # grizzly feature: -l for logging
  nosetests tempest/tempest/tests --with-xunit -d -l || echo ignore error code
  deactivate
  #. ~/venv/bin/activate
else
  #Uncomment dos.py string to erase vms and recreate lab from 0 (use BM provisioning)
  #dos.py erase $ENV_NAME
  nosetests -w fuel $test_name --with-xunit -d -l || echo ignore exit code
fi

.. note::

    Note text...

123

Configuration
-------------

Configuration ...

Common Issues
-------------

Issues ...
