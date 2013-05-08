::

Grizzly CI job example
==============================================

This is an example of grizzly TEMPEST job for CI cycle, i.e. commit & verify.

Quickstart
----------

Shell commands example for CI TEMPEST parameterized job
-------------------------------------------------------

Accepted values for test_name parameter are:
TEMPEST                                                      = full tempest run onto lab was deployed before
tempest/tempest/tests/.../ModuleName.py:ClassName.MethodName = run single tempest test specified only, 
(e.g. tempest/tempest/tests/compute/servers/test_create_server.py:ServersTestJSON.test_can_log_into_created_server)
Any other                                                    = redeploy lab from 'nodes-deployed' snapshots made after BM (dos.py uncomented will cause full redeploy with BM)

Other shell script keys:
CREATE_SNAPSHOTS                                             = Make snapshots after lab deployed (default False)
PUBLIC_POOL                                                  = Use new IP allocation pool for public & ext networking (use with dos.py only). See fuel_test/settings.py

. ~/work/venv/bin/activate
export ENV_NAME=$JOB_NAME
export CREATE_SNAPSHOTS=false
#export PUBLIC_POOL=172.18.91.128/25:26
export PUBLIC_POOL=172.18.91.0/24:27
if [ "$test_name" == "TEMPEST" ] || [ "$(echo $test_name | cut -d"/" -f1)" == "tempest" ]; then
  export run_tests=tempest/tempest/tests
  [ "$test_name" != "TEMPEST" ] && export run_tests="-v $test_name"
  # need protect 
  pushd fuel
    #pip install python-keystoneclient==0.2.3
    #pip install python-quantumclient==2.2.1 
    # Add || true for tempest reentrable
    PYTHONPATH=. python fuel_test/prepare.py || true
  popd
  #
  deactivate
  cp tempest.conf $WORKSPACE/tempest/etc/
  virtualenv venv --no-site-packages
  . venv/bin/activate
  pip install -r tempest/tools/pip-requires
  nosetests $run_tests --with-xunit -d || echo ignore error code
  deactivate
  #. ~/venv/bin/activate
else
  #Uncomment dos.py string to erase vms and recreate lab from 0 (use BM provisioning)
  #dos.py erase $ENV_NAME
  nosetests -w fuel $test_name --with-xunit -s -d || echo ignore exit code
fi

