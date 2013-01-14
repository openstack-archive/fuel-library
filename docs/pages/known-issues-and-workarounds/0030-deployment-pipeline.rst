
The process of redeploying the same environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Overview
--------

    Because Puppet is additive only, there was no ability to revert changes as you would in a typical application deployment.
    If a change needs to be backed out, you must explicitly add configuration to reverse it, check this configuration in,
    and promote it to production using the pipeline. This meant that if a breaking change did get deployed into production,
    typically a manual fix was applied, with the proper fix checked into version control subsequently.


Deployment pipeline
~~~~~~~~~~~~~~~~~~~

    * Deploy

    in order to deploy the multiple environments that aren't interfere with each other
    you should specify the ``$deployment_id`` option (set it to an even integer value (valid range is 0..254)).
    First of all it is involved in the dynamic environment-based tag generation  and globally apply that tag to all resources on each node.
    It is also used for keepalived daemon, there is a unique virtual_router_id evaluated.

    * Clean/Revert

    At this stage you just need to make sure the environment has the original/virgin state.

    * Puppet node deactivate

    This will ensure that any resources exported by that node will stop appearing in the catalogs served to the agent nodes:
    # ``puppet node deactivate <node>``
       where <node> is fully qualified domain name (``puppet cert list --all``)

    (automatic deactivate)
    # ``cert list --all | awk '! /DNS:puppet/ { gsub(/"/, "", $2); print $2}' | xargs puppet node deactivate``

    * Redeploy

    Fire up the puppet agent again to apply a desired node configuration


Links
~~~~

* http://puppetlabs.com/blog/a-deployment-pipeline-for-infrastructure/

