Large Scale Deployments
-----------------------

When deploying large clusters -- those of 100 nodes or more -- there are two basic bottlenecks:

* Certificate signing requests and Puppet Master/Cobbler capacity
* Downloading of operating systems and other software

All of these bottlenecks can be mitigated with careful planning.

If you are deploying Fuel 2.1 from the ISO, Fuel takes care of these problems by careful use of caching and orchestration, but it's good to have a sense of how to solve these problems.

Certificate signing requests and Puppet Master/Cobbler capacity
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


When deploying a large cluster, you may find that Puppet Master begins to have difficulty when you start exceeding 20 or more simultaneous requests. Part of this problem is because the initial process of requesting and signing certificates involves \*.tmp files that can create conflicts.  To solve this problem, you have two options: reduce the number of simultaneous requests, or increase the number of Puppet Master/Cobbler servers.

Reducing the number of simultaneous requests is a simple matter of staggering Puppet agent runs.  Orchestration can provide a convenient way to accomplish this goal.  You don't need extreme staggering -- 1 to 5 seconds will do -- but if this method isn't practical, you can increase the number of Puppet Master/Cobbler servers.

If you're simply overwhelming the Puppet Master process and not running into file conflicts, one way to get around this problem is to use Puppet Master with Thin as a backend and nginx as a front end.  This configuration will enable you to dynamically scale the number of Puppet Master processes up and down to accommodate load.

You can find sample configuration files for nginx and puppetmasterd at [CONTENT NEEDED HERE].

You can also increase the number of servers by creating a cluster of servers behind a round robin DNS managed by a service such as HAProxy. You will also need to ensure that these nodes are kept in sync.  For Cobbler, that means a combination of the --replicate switch, XMLRPC for metadata, rsync for profiles and distributions.  Similarly, Puppet Master and PuppetDB can be kept in sync with a combination of rsync (for modules, manifests, and SSL data) and database replication.

.. image:: /pages/production-considerations/cobbler-puppet-ha.png

Downloading of operating systems and other software
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Large deployments also suffer from a bottleneck in terms of downloading of software.  One way to avoid this problem is the use of multiple 1G interfaces bonded together.  You might also want to consider 10G Ethernet, if the rest of your architecture warrants it.  (See "Sizing Hardware" for more information on choosing networking equipment.)

Another option is to prevent the need to download so much data in the first place using either apt-cacher, which acts as a repository cache, or a private repository.

To use apt-cacher, the kickstarts Cobbler provides to each node should specify Cobbler's IP address and the apt-cacher port as the proxy server.  This will prevent all of the nodes from having to download the software individually.

`Contact Mirantis <http://www.mirantis.com/contact/>`_ for information on creating a private repository.
