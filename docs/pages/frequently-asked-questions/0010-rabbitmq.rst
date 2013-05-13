
RabbitMQ
^^^^^^^^

**Difficulty restarting RabbitMQ after a total failure**


**Issue:** 
In general, all RabbitMQ nodes must not be shut down simultaneously. RabbitMQ requires
that after a full shutdown of the cluster, the first node brought up should
be the last one to shut down, but it's not always possible to know which node that is, or even to ensure a clean shutdown.  Version 2.1 of Fuel solves this problem by managing the restart of
available nodes, so you should not experience difficulty with this issue.

If, however, you are still using previous versions of Fuel, here is how Fuel 2.1 works around this problem in case you need to do it yourself.

**Workaround:** 
There are 2 possible scenarios, depending on the results of the shutdown:

    #. The RabbitMQ master node is alive and can be started.
    #. It's impossible to start the RabbitMQ master node due to a hardware or system failure

Fuel 2.1 updates the ``/etc/init.d/rabbitmq-server`` init scripts for RHEL/Centos and Ubuntu to customized versions. These scripts attempt to start RabbitMQ twice, giving the RabbitMQ master node the necessary time to start after complete power loss. 

With the scripts in place, power up all nodes, then check to see whether the RabbitMQ server started on all nodes. All nodes should start automatically.

On the other hand, if the RabbitMQ master node has failed, the init script performs the following actions during the rabbitmq-server start. It moves the existing Mnesia database to a backup directory, and then makes a third and last attempt to start the RabbitMQ server.  In this case, RabbitMQ starts with clean database, and the live rabbit nodes assemble a new cluster. The script uses the current RabbitMQ settings to find the current Mnesia location and creates a backup directory in the same path as Mnesia, tagged with the current date.

So with the customized init scripts included in Fuel 2.1, in most cases RabbitMQ simply starts after complete power loss and automatically assembles the cluster, but you can manage the process yourself.


**Background:** See http://comments.gmane.org/gmane.comp.networking.rabbitmq.general/19792.

.. _https://launchpad.net/galera: https://launchpad.net/galera
.. _CentOS 6.3: http://isoredirect.centos.org/centos/6/isos/x86_64/
.. _http://wiki.vps.net/vps-net-features/cloud-servers/template-information/galeramysql-recommended-cluster-configuration/: http://wiki.vps.net/vps-net-features/cloud-servers/template-information/galeramysql-recommended-cluster-configuration/
.. _http://comments.gmane.org/gmane.comp.networking.rabbitmq.general/19792: http://comments.gmane.org/gmane.comp.networking.rabbitmq.general/19792
.. _http://puppetlabs.com/blog/a-deployment-pipeline-for-infrastructure/: http://puppetlabs.com/blog/a-deployment-pipeline-for-infrastructure/
.. _http://download.mirantis.com/epel-fuel/: http://download.mirantis.com/epel-fuel/
.. _Creating the virtual machines: http://#
.. _http://projects.reductivelabs.com/issues/2244: http://projects.reductivelabs.com/issues/2244
.. _https://bugs.launchpad.net/codership-mysql/+bug/1087368: https://bugs.launchpad.net/codership-mysql/+bug/1087368
.. _https://groups.google.com/forum/?fromgroups=#!topic/puppet-users/OpCBjV1nR2M: https://groups.google.com/forum/?fromgroups=#!topic/puppet-users/OpCBjV1nR2M
.. _https://www.virtualbox.org/wiki/Downloads: https://www.virtualbox.org/wiki/Downloads
.. _Overview: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id8
.. _Environments: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id9
.. _Useful links: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id6
.. _The process of redeploying the same environment: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id7
.. _Galera cluster has no built-in restart or shutdown mechanism: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id4
.. _The right way to get Galera up and working: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id5
.. _At least one RabbitMQ node must remain operational: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id2
.. _Galera: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id3
.. _RabbitMQ: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id1
.. _http://docs.puppetlabs.com/guides/environment.html: http://docs.puppetlabs.com/guides/environment.html
.. _Deployment pipeline: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id10
.. _Links: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/known-issues-and-workarounds/#id11
.. _http://10.0.1.10/: http://10.0.1.10/
.. _contact Mirantis for further assistance: http://www.mirantis.com/
.. _https://launchpad.net/codership-mysql: https://launchpad.net/codership-mysql
.. _http://projects.puppetlabs.com/issues/4680: http://projects.puppetlabs.com/issues/4680
.. _http://www.codership.com/wiki/doku.php: http://www.codership.com/wiki/doku.php
.. _http://projects.puppetlabs.com/issues/3234: http://projects.puppetlabs.com/issues/3234
.. _Enabling Stored Configuration: http://fuel.mirantis.com/reference-documentation-on-fuel-folsom/installing-configuring-puppet-master-2/#puppet-master-stored-config
.. _http://openlife.cc/blogs/2011/july/ultimate-mysql-high-availability-solution: http://openlife.cc/blogs/2011/july/ultimate-mysql-high-availability-solution
.. _http://www.google.com: http://www.google.com/


