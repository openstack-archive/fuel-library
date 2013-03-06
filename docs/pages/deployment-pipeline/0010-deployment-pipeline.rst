
Overview
--------

  Because Puppet is additive only, there was no ability to revert changes as you would in a typical application deployment.
  If a change needs to be backed out, you must explicitly add configuration to reverse it, check this configuration in,
  and promote it to production using the pipeline. This meant that if a breaking change did get deployed into production,
  typically a manual fix was applied, with the proper fix checked into version control subsequently.

  FUEL gives you the ability for isolating code changes while developing combined with minimizing the headaches
  with maintaining multiple environments serviced by one puppet server.


Environments
------------

  Puppet supports putting nodes in environments, this maps cleanly to your development, QA and production life cycles
  and it’s a way to hand out different code to different nodes.

  * On the Master/Server Node

    The puppetmaster tries to find modules using its modulepath setting, typically something like ``/etc/puppet/modules``.
    You usually just set this value once in your ``/etc/puppet/puppet.conf`` and that’s it, all done.
    Environments expand on this and give you the ability to set different settings for different environments.

    You can specify several search paths. The following example dynamically sets the modulepath
    so Puppet will check a per-environment folder for a module before serving it from the main set::

      [master]
        modulepath = $confdir/$environment/modules:$confdir/modules

      [production]
        manifest   = $confdir/manifests/site.pp

      [development]
        manifest   = $confdir/$environment/manifests/site.pp

  * On the Agent Node

    Once agent node makes a request, the puppet master gets informed of its environment.
    If you don’t specify an environment, the agent has the default ``production`` environment.

    To set an environment agent-side, just specify the environment setting in the [agent] block of ``puppet.conf``::

      [agent]
        environment = development


Deployment pipeline
-------------------

  * Deploy

    In order to deploy the multiple environments that aren't interfere with each other
    you should specify the ``$deployment_id`` option in ``/etc/puppet/manifests/site.pp`` (set it to an even integer value (valid range is 0..254)).

    First of all it is involved in the dynamic environment-based tag generation and globally apply that tag to all resources on each node.
    It is also used for keepalived daemon, there is a unique virtual_router_id evaluated.

  * Clean/Revert

    At this stage you just need to make sure the environment has the original/virgin state.

  * Puppet node deactivate

    This will ensure that any resources exported by that node will stop appearing in the catalogs served to the agent nodes:

      ``puppet node deactivate <node>``
        where <node> is fully qualified domain name (``puppet cert list --all``)

    You can deactivate a node manually one by one or execute the following command to automatically make the same

      ``cert list --all | awk '! /DNS:puppet/ { gsub(/"/, "", $2); print $2}' | xargs puppet node deactivate``

  * Redeploy

    Fire up the puppet agent again to apply a desired node configuration


Links
-----

  * http://puppetlabs.com/blog/a-deployment-pipeline-for-infrastructure/
  * http://docs.puppetlabs.com/guides/environment.html
