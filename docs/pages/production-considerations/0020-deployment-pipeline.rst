Redeploying an environment
--------------------------

Because Puppet is additive only, there is no ability to revert changes as you would in a typical application deployment.
If a change needs to be backed out, you must explicitly add a configuration to reverse it, check this configuration in,
and promote it to production using the pipeline. This means that if a breaking change did get deployed into production,
typically a manual fix was applied, with the proper fix subsequently checked into version control.

Fuel combines the ability to isolate code changes while developing with minimizing the headaches associated
with maintaining multiple environments serviced by one puppet server by creating environments


Environments
^^^^^^^^^^^^

Puppet supports putting nodes into separate 'environments'. These environments can map cleanly to your development, QA and production life cycles, so it’s a way to hand out different code to different nodes.

* On the Master/Server Node

  The Puppet Master tries to find modules using its ``modulepath`` setting, which is typically something like ``/etc/puppet/modules``. You usually just set this value once in your ``/etc/puppet/puppet.conf``.  Environments expand on this idea and give you the ability to use different settings for different environments.

  For example, you can specify several search paths. The following example dynamically sets the ``modulepath`` so Puppet will check a per-environment folder for a module before serving it from the main set::

      [master]
        modulepath = $confdir/$environment/modules:$confdir/modules

      [production]
        manifest   = $confdir/manifests/site.pp

      [development]
        manifest   = $confdir/$environment/manifests/site.pp

* On the Agent Node

  Once the agent node makes a request, the Puppet Master gets informed of its environment. If you don’t specify an environment, the agent uses the default ``production`` environment.

  To set an environment agent-side, just specify the environment setting in the ``[agent]`` block of ``puppet.conf``::

      [agent]
        environment = development


Deployment pipeline
^^^^^^^^^^^^^^^^^^^

* Deploy

  In order to deploy multiple environments that don't interfere with each other, you should specify the ``$deployment_id`` option in ``/etc/puppet/manifests/site.pp``.  It should be an even integer value in the range of 2-254.

  This value is used in dynamic environment-based tag generation.  Fuel also apply that tag globally to all resources on each node.  It is also used for the keepalived daemon, which evaluates a unique ``virtual_router_id``.

* Clean/Revert

  At this stage you just need to make sure the environment has the original/virgin state.

* Puppet node deactivate

  This will ensure that any resources exported by that node will stop appearing in the catalogs served to the agent nodes::

      puppet node deactivate <node>

  where ``<node>`` is the fully qualified domain name as seen in ``puppet cert list --all``.

  You can deactivate nodes manually one by one, or execute the following command to automatically deactivate all nodes::

      cert list --all | awk '! /DNS:puppet/ { gsub(/"/, "", $2); print $2}' | xargs puppet node deactivate

* Redeploy

  Fire up the puppet agent again to apply a desired node configuration


Links
^^^^^

* http://puppetlabs.com/blog/a-deployment-pipeline-for-infrastructure/
* http://docs.puppetlabs.com/guides/environment.html
