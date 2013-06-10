::

Grizzly CI TEMPEST parameterized job example
==============================================

This is an example of grizzly TEMPEST job for CI cycle, i.e. commit & verify.

Quickstart
----------

- Copy job from the nearest-best-fitting-one, edit job name to match its environment
- Set up SCM for repos needed and provide its local directories names (fuel & tempest is a minimum required)
- Add parameters for job, f.e. ``test_name`` with values

     - fuel_test.cobbler.test_simple:SimpleTestCase.test_simple
     - fuel_test.cobbler.test_simple
     - fuel_test.cobbler.test_single
     - fuel_test.cobbler.test_full:FullTestCase.test_full
     - fuel_test.cobbler.test_compact:CompactTestCase.test_deploy_compact_quantum
     - fuel_test.cobbler.test_compact:CompactTestCase.test_deploy_compact_wo_quantum
     - fuel_test.cobbler.test_quantum_standalone_no_swift:QstTestCase.test_quantum_standalone_no_swift
     - fuel_test.cobbler.test_minimal:MinimalTestCase.test_minimal
     - fuel_test.cobbler.test_orchestration:CobblerCase.test_orchestrating_minimal
     - TEMPEST
     - tempest/tempest/tests/network/test_network_basic_ops.py
     - tempest/tempest/tests/compute/servers/test_create_server.py:ServersTestJSON.test_can_log_into_created_server
     - tempest/tempest/tests/compute/floating_ips

  and ``erase`` with values
    
     - false
     - true

- Configure shell command to execute
- Run the job

Shell env. varaibles used for job
---------------------------------

Accepted values for ``test_name`` parameter are

- TEMPEST = full tempest run onto lab was deployed before
- tempest/tempest/tests/.../ModuleName.py:ClassName.MethodName = run single tempest test specified only, e.g. tempest/tempest/tests/compute/servers/test_create_server.py:ServersTestJSON.test_can_log_into_created_server
- Any other = redeploy lab from 'nodes-deployed' snapshots have been made after BM by cobbler have finished (uncomented dos.py would cause full erase and redeploy with BM including vm networks recreation)

Accepted values for ``erase`` parameter are

- false = do not erase existing virtual nodes and networks before nosetests execution
- true = run dos.py script to erase and recreate virtual networks and nodes for lab, next run the nosetests (note: always use ``true`` if public_pool have changed)

Other shell script keys

- DOMAIN_NAME = domain name to use for nodes (default ``.your-domain-name.com``), note: this option is broken
- OS_FAMILY   = OS type for nodes, ``cetnos`` or ``ubuntu`` (default ``centos``)
- CURRENT_PROFILE = ``centos64_x86_64`` or ``ubuntu_1204_x86_64`` - cobbler ks profile to use (default depends on OS_FAMILY)
- CONTROLLERS,COMPUTES,STORAGES,PROXIES = number of nodes of corresponding role type to deploy (defaults ``3,3,3,2``)
- PARENT_PROXY = parent-proxy server for squid at master node (``172.18.67.168`` Saratov, ``172.18.3.14`` Moscow) (default none)
- CIRROS_IMAGE = cirros url (default ``http://srv08-srt.srt.mirantis.net/cirros-0.3.0-x86_64-disk.img``)
- ISO_IMAGE = Fuel iso image to use for master node (default ``~/fuel-centos-6.4-x86_64.iso``)
- USE_ISO  = use ISO for deployment (default ``True``), note: this option is broken
- ASTUTE_USE = use astute addon for mcollective to deploy nodes (default ``True``)
- PUPPET_GEN = puppet generation ``(2,3)`` to use, i.e. ``2 => v2.x.x``, ``3 => v3.x.x`` (default ``2``)
- PUPPET_AGENT_COMMAND = command to run puppet agents (default ``puppet agent -tvd -evaltrace 2>&1``)
- CLEAN = clean exitsting dirty state, will revert nodes to snapshot ``nodes-deployed``, if any (default ``True``)
- CREATE_SNAPSHOTS = make ``openstack`` snapshots after lab have deployed or ``openstack-upgraded`` in case of upgrade (default ``False``)
- UPGRADE = tell jenkins to revert nodes to ``openstack`` snapshots while cleaning (default ``False``)
- PUBLIC_POOL = use custom IP allocation pool for public & ext networking (use with dos.py only). See also: fuel_test/settings.py, note: this option is broken
- PUBLIC_FORWARD = ``nat`` or ``route`` forwarding mode for public pool, use ``route`` for custom forwarded pools (default ``nat``)

Shell script example
--------------------

.. code:: bash
 
   . ~/work/venv/bin/activate
   export ENV_NAME=$JOB_NAME
   export PUPPET_AGENT_COMMAND='puppet agent -t 2>&1'
   export CREATE_SNAPSHOTS=true
   export UPGRADE=false
   export CLEAN=true
   export PUPPET_GEN=2
   export ASTUTE_USE=false

   export PARENT_PROXY=172.18.67.168
   export CIRROS_IMAGE=http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img
   export ISO=/var/lib/libvirt/images/fuel-centos-6.3-x86_64.iso

   export CONTROLLERS=1
   export COMPUTES=3
   export STORAGES=0
   export PROXIES=0

   export OS_FAMILY=centos
   export CURRENT_PROFILE=centos64_x86_64

   if [ "$test_name" == "TEMPEST" ] || [ "$(echo $test_name | cut -d"/" -f1)" == "tempest" ]; then
      export run_tests=tempest/tempest/tests
      [ "$test_name" != "TEMPEST" ] && export run_tests="-v $test_name"
      pushd fuel
          pip install -r fuel_test/pip-requires
          PYTHONPATH=. python fuel_test/prepare.py || true
      popd
      deactivate
      cp tempest.conf $WORKSPACE/tempest/etc/
      virtualenv venv --no-site-packages
      . venv/bin/activate
      pip install -r tempest/tools/pip-requires
      nosetests $run_tests --with-xunit -d -l DEBUG || echo ignore error code
      deactivate
   else
      [ "$erase" == "true" ] && dos.py erase $ENV_NAME
      nosetests -w $fuel_release $test_name --with-xunit -s -d -l DEBUG || echo ignore exit code
   fi

