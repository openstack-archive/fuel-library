Deploying OpenStack
-------------------

You have two options for deploying OpenStack.  The eaiser method is to use orchestration, but you can also deploy your nodes manually.

.. _orchestration:

Deploying via orchestration
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Manually installing a handful of servers might be managable, but repeatable installations, or those that involve a large number of servers, require automated orchestration.  Now you can use orchestration with Fuel through the ``astute`` script.  This script is configured using the ``astute.yaml`` file you created when you ran ``openstack_system``.

To confirm that your servers are ready for orchestration, execute the command::

  mco ping

You should see all three controllers, plus the compute node, answer the call::

  fuel-compute-01                                    time=107.26 ms
  fuel-controller-01                                 time=120.14 ms
  fuel-controller-02                                 time=135.94 ms
  fuel-controller-03                                 time=139.33 ms

To run the orchestrator, log in to ``fuel-pm`` and execute::

  astute -f astute.yaml

You will see a message on ``fuel-pm`` stating that the installation has started on fuel-controller-01.  To see what's going on on the target node, type::

  tail -f /var/log/syslog

for Ubuntu, or::

  tail -f /var/log/messages

for CentOS/Red Hat.

Note that Puppet will require several runs to install all the different roles, so the first time it runs, the orchestrator will show an error, but it just means that the installation isn't complete.  Also, after the first run on each server, the orchestrator doesn't output messages on fuel-pm; when it's finished running, it will return you to the command prompt.  In the meantime, you can see what's going on by watching the logs on each individual machine.


