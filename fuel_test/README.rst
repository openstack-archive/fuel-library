::

Grizzly CI TEMPEST parameterized job example
==============================================

This is an example of grizzly TEMPEST job for CI cycle, i.e. commit & verify.

Quickstart
----------

- Copy job from the nearest-best-fitting-one, edit job name to match its environment
- Set up SCM for repos needed and provide its local directories names (fuel & tempest is a minimum required)
- Add parameters for job, e.g.:
      fuel_test.cobbler.test_simple:SimpleTestCase.test_simple
      TEMPEST
      tempest/tempest/tests/network/test_network_basic_ops.py
      tempest/tempest/tests/compute/servers/test_create_server.py:ServersTestJSON.test_can_log_into_created_server
      tempest/tempest/tests/compute/floating_ips
- Configure shell command to execute
- Run the job

Shell env. varaibles used for job
-------------------------------------------------------

Accepted values for test_name parameter are:

TEMPEST                                      = full tempest run onto lab was deployed before
tempest/tempest/tests/.../ModuleName.py:ClassName.MethodName = run single tempest test specified only, 
                                            (e.g. tempest/tempest/tests/compute/servers/test_create_server.py:ServersTestJSON.test_can_log_into_created_server)
Any other                                    = redeploy lab from 'nodes-deployed' snapshots had made after BM by cobbler have finished
                                            (uncomented dos.py would cause full erase and redeploy with BM including vm networks recreation)

Other shell script keys:
PUPPET_GEN				     = puppet generation (2,3) to use with master & agents, i.e. 2 => v2.x.x, 3 => v3.x.x (default 3)
DEBUG                                        = run puppet with '-tvd -evaltrace' args
CLEAN                                        = clean exitsting dirty state before to proceed (default True)
CREATE_SNAPSHOTS                             = make 'openstack' snapshots after lab have deployed or 'openstack-upgraded' in case of upgrade (default False)
UPGRADE                                      = tell jenkins to revert to 'openstack' snapshotes instead of 'nodes-deployed' (default False)
PUBLIC_POOL                                  = use new IP allocation pool for public & ext networking (use with dos.py only). See also: fuel_test/settings.py

Shell script example
--------------------

~/work/venv/bin/activate
export ENV_NAME=$JOB_NAME
export DEBUG=true
export CREATE_SNAPSHOTS=true
export UPGRADE=false
export CLEAN=true
export PUPPET_GEN=2
export PUBLIC_POOL=172.18.91.128/25:26
#export PUBLIC_POOL=172.18.91.0/24:27
if [ "$test_name" == "TEMPEST" ] || [ "$(echo $test_name | cut -d"/" -f1)" == "tempest" ]; then
  export run_tests=tempest/tempest/tests
  [ "$test_name" != "TEMPEST" ] && export run_tests="-v $test_name"
  # need protect 
  pushd fuel
    #pip install python-keystoneclient==0.2.3
    #pip install python-quantumclient==2.2.1 
    PYTHONPATH=. python fuel_test/prepare.py || true
  popd
  deactivate
  cp tempest.conf $WORKSPACE/tempest/etc/
  virtualenv venv --no-site-packages
  . venv/bin/activate
  pip install -r tempest/tools/pip-requires
  nosetests $run_tests --with-xunit -d || echo ignore error code
  deactivate  
else
  [ "$erase" == "true" ] && dos.py erase $ENV_NAME
  nosetests -w $fuel_release $test_name --with-xunit -s -d || echo ignore exit code
  # Kill vms not needed
  for i in quantum swiftproxy-01 swiftproxy-02 swift-01 swift-02 swift-03 controller-02 controller-03;\
    do virsh destroy "${ENV_NAME}_fuel-${i}" || echo ignore exit code; done
fi

