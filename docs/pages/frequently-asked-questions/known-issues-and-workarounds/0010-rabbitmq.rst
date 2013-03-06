
RabbitMQ
^^^^^^^^

**At least one RabbitMQ node must remain operational**


**Issue:** 
All RabbitMQ nodes must not be shut down simultaneously. RabbitMQ requires
that, after a full shutdown of the cluster, the first node to bring up should
be the last one to shut down.

**Workaround:** 
There are 2 possible scenarios, depending on shutdown results.

**1. RabbitMQ master node alive and can be started.**

FUEL installation updates ``/etc/init.d/rabbitmq-server`` init scripts for RHEL/Centos and Ubuntu to customized versions. These scripts attempt to start RabbitMQ 5 times and so give RabbitMQ master node necessary time to start
after complete power loss. 
It is recommended to power up all nodes and then check if RabbitMQ server started on all nodes. All nodes should start automatically.

**2. Impossible to start RabbitMQ master node (hardware or system failure)**

There is no easy automatic way to resolve this situation.
Proposed solution is to delete mirrored queue directly from mnesia (RabbitMQ database)

1. Select any alive node. Run

``erl -mnesia dir '"/var/lib/rabbitmq/mnesia/rabbit\@<failed_controller_name>"'``

2. Run ``mnesia:start().`` in Erlang console.

3. Compile and run the following Erlang script::

    AllTables = mnesia:system_info(tables),
    DataTables = lists:filter(fun(Table) -> Table =/= schema end,
                          AllTables),
    RemoveTableCopy = fun(Table,Node) ->
    Nodes = mnesia:table_info(Table,ram_copies) ++
          mnesia:table_info(Table,disc_copies) ++
          mnesia:table_info(Table,disc_only_copies),
    case lists:is_member(Node,Nodes) of
      true -> mnesia:del_table_copy(Table,Node);
      false -> ok
    end
    end,
    RemoveTableCopy(Tbl,'rabbit@<failed_controller_name>') || Tbl <- DataTables.
    rpc:call('rabbit@<failed_controller_name>',mnesia,stop,[]),
    rpc:call('rabbit@<failed_controller_name>',mnesia,delete_schema,[SchemaDir]),
    RemoveTablecopy(schema,'rabbit@<failed_controller_name>').

4. Exit Erlang console ``halt().``

5. Run ``service rabbitmq-server start``

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


