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
        export PUBLIC_POOL=172.18.91.0/24:27
        #Uncomment dos.py string to recreate lab from 0 (use BM provisioning)
        #dos.py erase $ENV_NAME
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
          nosetests tempest/tempest/tests -s --with-xunit  || echo ignore error code
          deactivate
          #. ~/venv/bin/activate
        else
          nosetests -w fuel $test_name --with-xunit -s || echo "ignore exit code" 
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
