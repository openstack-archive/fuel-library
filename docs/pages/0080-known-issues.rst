Known issues
=============

.. contents:: :local:

1. At least one RabbitMQ node must remain operational
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Issue:** RabbitMQ nodes must not be shut down all at once. RabbitMQ requires
that, after a full shutdown of the cluster, the first node to bring up should
be the last one to shut down.

**Workaround:** If you experienced a complete power loss, it's recommended to
power up all nodes and then manually start RabbitMQ on all of them within 30
seconds, e.g. using an ssh script. If you failed, stop all RabbitMQ's (you might
need to do that using `kill -9` as `rabbitmqctl stop` may hang after such a
failure) and try starting them in different orders.

There is no easy automatic way to determine which node terminated last and so
should be brought up first, it's just trial and error.

**Background:** See http://comments.gmane.org/gmane.comp.networking.rabbitmq.general/19792.

_

_

2. Galera cluster has no built-in restart or shutdown mechanism
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Issue:** Galera cluster cannot be simply started or stopped. It supposed to work continuously

_

**Workaround:**
 
 The right way to get Galera up and working
 -------------------------------------------------------------------------------------

Galera, as high availability software, does not include built-in full cluster shutdown or restart sequence.

It is supposed to be running on 24/7/365 basis. From other side, deploying, updating or restarting Galera may lead to different issues. 
This guide helps to avoid some of these issues.

Usual Galera cluster startup includes combination of the procedures, described below. 
These procedures, with some differences, are performed by FUEL manifests.

_ 

Stop single Galera node
~~~~~~~~~~~~~~~~~~~~~~~

There is no dedicated Galera process - Galera works inside MySQL server process. MySQL server should be patched with Galera WSREP patch to be able to work as Galera cluster.

All Galera stop steps listed below are automatically performed by mysql init script, supplied by FUEL installation manifests, so in most cases it should be enough to perform the first step only. In case even init script fails in some (we hope rare) circumstances, repeat step 2 manually.

#. **First, run** 
    * ``service mysql stop``
    
    command. Wait some time, until you sure all mysql processes are shut down.


#. **Run**
    *  ``ps -ef | grep mysql``

     and stop **ALL(!) mysqld** and **mysqld_safe(!)** processes.
     Wait 20 seconds and check if mysqld processes running again. Stop or kill any new mysqld or mysqld_safe processes.
     It is very important to stop all MySQL processes - Galera uses mysqld_safe and it may start additional MySQL processes. So, even if there is no currently running processes visible, additional processes may be already in process of start. It is why we check running processes twice. Mysqld_safe has 15 seconds default timeout before process restart.
     If no mysqld processes running - node may be considered shut down.
     If there were nothing to kill and all MySQL processes stopped after `service mysql stop` command - node may be considered shut down gracefully.
 

_ 

Stop Galera cluster
~~~~~~~~~~~~~~~~~~~

Galera cluster is a master-master replication cluster. So, it is always in process of synchronization.

Recommended way to stop cluster is following:

#.  **Stop all requests to cluster from outside**

     * Default Galera non-synchronized cache size under heavy load may be up to 1 Gib - you may have to wait until every node is fully synced.
     Select first node to shut down - better to start from non-primary nodes.
     Connect to this node with mysql console.
    

     **Run** 

     * ``show status like 'wsrep_local_state%';``

     If it is **Synced** - then it is OK to begin shut down node. If node is non-synchronized, you may shut it down anyway, but avoid to start new cluster operation from this node in the future.
     
     **With mysql console run the following command:**

     * ``SET GLOBAL wsrep_on='OFF';``

     Replication stops immediately after **wsrep_on** variable is set to **OFF**. So, avoid performing any changes to the node after this setting is done.
     Exit from mysql console. Now, selected node exited cluster.



#.   **Perform steps,** 

     described in **Stop single Galera node** section.



#.   **Repeat steps 1 and 2 with every remained node.** 

     * Remember, which node you are going to shut down last - better if it would be primary node in synced state. This node is the best and recommended candidate to start up first when you decide to continue cluster operation.
 

_ 

Start Galera and create new cluster
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Galera writes its state to file **grastate.dat**, located at path, controlled by **wsrep_data_home_dir variable**, defaulting to **mysql_real_data_home**.

FUEL OpenStack deployment manifests also places this file to default path **/var/lib/mysql/grastate.dat**

This file is very useful to find out the node with most recent commit in case of unexpected cluster shutdown. Simply compare **UUID** values of **grastat.dat** from every node. The greater **UUID** value shows which node has latest commit.

In case the cluster was shut down gracefully and last shut down node is known - simply perform the steps below to start up the cluster. Or find the node with most recent commit using **grastat.dat** files and start cluster operation from found node.

**Steps:**

#.  **Ensure, all Galera nodes are shut down.**

    If one or more nodes are running up - they all will be outside new cluster until restart.
    Data integrity is not guaranteed in such case.



#.  **Select primary node**

    This node is supposed to start first and it creates new cluster ID and new last commit UUID (Variable **wsrep_cluster_state_uuid** represents this UUID inside MySQL process). 
    FUEL deployment manifests with default settings set up **fuel-01** to be both primary Galera cluster node and first deployed OpenStack controller.
    Open **/etc/mysql/conf.d/wsrep.cnf**
    Set empty cluster address as following, including quotation marks:

    ``wsrep_cluster_address="gcomm://"``

    Save changes to config file.
 

#.  **Run** 

    * ``service mysql start``

    command on the first primary node or restart MySQL if there were configuration changes to **wsrep.cnf**. 
    Connect to MySQL server.
    
    **Run the following command:** 

    * ``SET GLOBAL wsrep_on='ON';``

    to start replication within new cluster. This variable also may be set via **wsrep.cnf** file.
    Check new cluster status with the following command:

    * ``show status like 'wsrep%';``

    **wsrep_local_state_comment** should be **Synced**

    **wsrep_cluster_status** should be **Primary**

    **wsrep_cluster_size** should be **1** since no more additional cluster nodes started so far.

    **wsrep_incoming_addresses** should include only address of the current node.
 

#.  **Select one of secondary nodes**

    * Check its **/etc/mysql/conf.d/wsrep.cnf** file.

    **wsrep_cluster_address="gcomm://node1,node2"** variable should include name or IP address of already started primary node. Otherwise this node should definitely fail to start. 
    In case of OpenStack, deployed by FUEL manifests with default settings (2 controllers) this parameter should look like 

    ``wsrep_cluster_address="gcomm://fuel-01:4567,fuel-02:4567"``

    If **wsrep_cluster_address** is set correctly, run 

    * ``service mysql start``

    command on this node.
 

#.  **Connect to any node with mysql and run** 

    * ``show status like 'wsrep%';``

    command again.

    **wsrep_local_state_comment** should finally change from **Donor/Synced** or other statuses to **Synced**. Time to sync may vary depending on database size and connection speed.

    **wsrep_cluster_status** should be **Primary** on both nodes. Galera is master-master replication cluster and every node by default becomes primary (e. g. master). Galera also supports master-slave configuration for special purposes. Slave nodes has **Non-Primary** **wsrep_cluster_status** value.

    **wsrep_cluster_size** should be **2** since we just added one more node to cluster.

    **wsrep_incoming_addresses** should include addresses of both started nodes.


    `Note. State transfer is a heavy operation not only on the joining node, but also on donor, in particular state donor may be not able to serve client requests, or be plain slow.`

 

#.  **Repeat step 4 on all remained controllers**

    If all secondary controllers started successfully and became synced and you do not plan to restart cluster in nearest future, it is strongly recommended to change wsrep configuration setting on the first controller.
    Open **/etc/mysql/conf.d/wsrep.cnf** file.
    Set **wsrep_cluster_address=** to the same value (node list) as used for every secondary controller.
    In case of OpenStack, deployed by FUEL manifests with default settings (2 controllers) this parameter should finally look like 

    ``wsrep_cluster_address="gcomm://fuel-01:4567,fuel-02:4567"`` 

    on every operating controller.

    This step is important for future failures or maintenance procedures.
    In case Galera primary controller node is restarted with empty **gcomm** value (**wsrep_cluster_address="gcomm://"**) it creates new cluster and exits existing cluster. Existing cluster nodes also may stop receiving requests and synchronization process to prevent data de-synchronization issues.
 

_ 

`Note. Starting from version mysql` **5.5.28_wsrep23.7 (Galera version 2.2)** `Galera cluster supports additional start mode. Instead of setting`

``wsrep_cluster_address="gcomm://"``

`on the first node one may set the following URL for cluster address`

``wsrep_cluster_address="gcomm://node1,node2:port2,node3?pc.wait_prim=yes"``

`where nodeX is name or IP of one of available nodes, with optional port.`
`So, every Galera node may have same configuration file with list of all nodes. It designed to eliminate all configuration file changes on the first node after cluster is started.`
`After the nodes are started, with mysql one may set`

``pc.bootstrap=1``

`flag to the node, which should start new cluster and become primary.`
`All other nodes should automatically perform initial synchronization with this new primary node. This flag may be also provided for single selected node via wsrep.cnf configuration file as following`

``wsrep_cluster_address="gcomm://node1,node2:port2,node3?pc.wait_prim=yes&pc.bootstrap=1"``

`Unfortunately, due to a bug in mysql init script,` <https://bugs.launchpad.net/codership-mysql/+bug/1087368> `bootstrap flag is completely ignored in` **Galera 2.2 (wsrep_2.7)**. `So, to start up new cluster one should use old way with empty` **gcomm://** `URL.`
`All other nodes may have both, single node or multiple node list in gcomm URL, bug affects only first node, which starts up new cluster.`
`Please also note, nodes with non-empty gcomm URL may start only if at least one of the nodes, listed in` **gcomm://node1,node2:port2,node3** `is already started up and available for initial synchronization.`
`For every starting Galera node it is enough to have at least one working node name/address to get full information about cluster structure and to perform initial synchronization.`
`Actually` FUEL `deployment manifests with default settings may set (or may not set!)`

``wsrep_cluster_address="gcomm://"`` 

`on primary node (first deployed OpenStack controller) and node list like`

``wsrep_cluster_address="gcomm://fuel-01:4567,fuel-02:4567"`` 

`on every secondary controller. So, it is good idea to check these parameters after deployment finished.`


_

`Note. Galera cluster is very democratic system. As it is master-master cluster, every primary node equals to other primary nodes.`
`Primary nodes with same sync state (same` **wsrep_cluster_state_uuid** `value) forms so-called quorum - majority of primary nodes with same` **wsrep_cluster_state_uuid.**
`Normally, one of controllers get new commit, increases its` **wsrep_cluster_state_uuid** `value and performs synchronization with other nodes.`
`In case when one of primary controllers fails, Galera cluster continue serving requests as long as quorum exists.`
`Exit of the primary controller from cluster equals to failure, since after exit this controller has new cluster ID and` **wsrep_cluster_state_uuid** `value smaller then same value on long-working nodes.`
`So, 3 working primary controllers are the very minimal Galera cluster size. Recommended Galera cluster size is 6 controllers.`
`Yes,` FUEL `deployment manifests with default settings actually deploy non-recommended Galera configuration with 2 controllers only. It is suitable for testing purpose but not for production.`


_

Continue existing cluster after failure
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Continuing Galera cluster after power or other types of failure basically consist of two steps - backing up of every node and finding out of node with most recent non-damaged replica.

Helpful tip is to add 

``wsrep_provider_options="wsrep_on = off;"`` 

to **/etc/mysql/conf.d/wsrep.cnf** configuration file.

After these steps simply perform **Start Galera and create new cluster** procedure, starting from this found node, with most recent non-damaged replica.


_

Useful links
~~~~~~~~~~~~

http://www.codership.com/wiki/doku.php

Galera documentation from Galera authors.

_ 

https://launchpad.net/codership-mysql

https://launchpad.net/galera

Actual Galera and WSREP patch bug list and official Galera/WSREP bug tracker.

_ 

http://wiki.vps.net/vps-net-features/cloud-servers/template-information/galeramysql-recommended-cluster-configuration/

One of recommended Galera cluster robust configurations.

_ 

http://openlife.cc/blogs/2011/july/ultimate-mysql-high-availability-solution

Why we use Galera.

_ 

http://www.google.com

Other questions. Seriously, sometimes there is not enough info about Galera available in official Galera docs.