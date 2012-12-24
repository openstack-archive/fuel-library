Known Issues and Workarounds
============================


Galera
^^^^^^

Galera cluster has no built-in restart or shutdown mechanism
------------------------------------------------------------

**Issue:**
Galera cluster cannot be simply started or stopped. It is supposed to work continuously.

**Workaround:**

 
The right way to get Galera up and working
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Galera, as high availability software, does not include any built-in full cluster shutdown or restart sequence.

It is supposed to be running on a 24/7/365 basis. 
On the other side, deploying, updating or restarting Galera may lead to different issues. 
This guide is intended to help avoid some of these issues.

Regular Galera cluster startup includes a combination of the procedures described below. 
These procedures, with some differences, are performed by Fuel manifests.
 

**1. Stop a single Galera node**

There is no dedicated Galera process - Galera works inside MySQL server process. 
MySQL server should be patched with Galera WSREP patch to be able to work as Galera cluster.

All Galera stop steps listed below are automatically performed by the mysql init script 
supplied by Fuel installation manifests, so in most cases it should be enough to perform the first step only. 
In case even init script fails in some (rare, as we hope) circumstances, repeat step 2 manually.

#. Run ``service mysql stop``.
     Wait some time to ensure all MySQL processes are shut down.


#. Run ``ps -ef | grep mysql`` and stop ALL(!) **mysqld** and **mysqld_safe** processes.
     * Wait 20 seconds and check if the mysqld processes are running again. 
     * Stop or kill any new mysqld or mysqld_safe processes.

     It is very important to stop all MySQL processes - Galera uses ``mysqld_safe`` 
     and it may start additional MySQL processes. 
     So, even if there is no currently running processes visible, additional processes may be already in process of start. 
     That is why we check running processes twice. ``mysqld_safe`` has the default timeout 15 seconds before process restart.
     If no ``mysqld`` processes are running, the node may be considered shut down.
     If there was nothing to kill and all MySQL processes stopped after the ``service mysql stop`` command - 
     the node may be considered shut down gracefully.
  

**2. Stop the Galera cluster**

Galera cluster is a master-master replication cluster. Therefore, it is always in the process of synchronization.

The recommended way to stop the cluster includes the following steps:

#.  Stop all requests to the cluster from outside

     * Default Galera non-synchronized cache size under heavy load may be up to 1 Gib - you may have to wait until every node is fully synced.

     Select the first node to shut down - better to start from non-primary nodes.
     Connect to this node with mysql console.
    
     * Run ``show status like 'wsrep_local_state%';``

     If it is "Synced", then it is OK to start the shutdown node procedure. 
     If the node is non-synchronized, you may shut it down anyway, but avoid to start a new cluster operation 
     from this node in the future.
     
     * In mysql console, run the following command:

       * ``SET GLOBAL wsrep_on='OFF';``

     Replication stops immediately after the ``wsrep_on`` variable is set to "OFF". 
     So, avoid making any changes to the node after this setting is done.

     * Exit from mysql console. 
     
     Now, the selected node exited cluster.

                                   
#.   Fulfil the steps described in the **Stop single Galera node** section.

                                   
#.   Repeat steps 1 and 2 for each remaining node. 

     * Remember which node you are going to shut down last - ideally, it should be the primary node in the synced state. This node is the best and the recommended candidate to start up first when you decide to continue cluster operation.
 

**3. Start Galera and create a new cluster**

Galera writes its state to file ``grastate.dat`` that resides in the location specified in 
``wsrep_data_home_dir variable``, defaulting to "mysql_real_data_home".

Fuel OpenStack deployment manifests also place this file to the default location, path: ``/var/lib/mysql/grastate.dat``.

This file is very useful to find out the node with the most recent commit in case of unexpected cluster shutdown. 
Simply compare the "UUID" values of ``grastat.dat`` from every node. 
The greater "UUID" value indicates which node has the latest commit.

In case the cluster was shut down gracefully and last shut down node is known - 
simply perform the steps below to start up the cluster. 
Alternatively, you can find the node with the most recent commit using the ``grastat.dat`` files 
and start the cluster operation from the node found.

#.  Ensure that all Galera nodes are shut down

    If one or more nodes are running, they all will be outside the new cluster until restart.
    Note that data integrity is not guaranteed in such case.
               
#.  Select the primary node

    This node is supposed to start first. It creates a new cluster ID and a new last commit UUID 
    (the ``wsrep_cluster_state_uuid`` variable represents this UUID inside the MySQL process). 
    Fuel deployment manifests with default settings set up ``fuel-01`` to be both the primary Galera cluster node 
    and the first deployed OpenStack controller.
    * Open ``/etc/mysql/conf.d/wsrep.cnf``
    * Set empty cluster address as follows (including quotation marks):

    ``wsrep_cluster_address="gcomm://"``

    * Save changes to the config file.

#.  Run the ``service mysql start`` command on the first primary node or restart MySQL 
    if there were configuration changes to ``wsrep.cnf``. 
    
    * Connect to MySQL server.
    
    * Run the ``SET GLOBAL wsrep_on='ON';`` to start replication within the new cluster. This variable can also be set by editing the ``wsrep.cnf`` file.
    
    * Check the new cluster status by running the following command: ``show status like 'wsrep%';``

      * ``wsrep_local_state_comment`` should be "Synced"

      * ``wsrep_cluster_status`` should be "Primary"

      * ``wsrep_cluster_size`` should be "1", since no more cluster nodes have been started so far.

      * ``wsrep_incoming_addresses`` should include only the address of the current node.
 

#.  Select one of the secondary nodes

    * Check its ``/etc/mysql/conf.d/wsrep.cnf`` file.

      * The ``wsrep_cluster_address="gcomm://node1,node2"`` variable should include the name or IP address 
        of already started primary node. Otherwise, this node will definitely fail to start. 
        In case of OpenStack deployed by Fuel manifests with default settings (2 controllers), 
        this parameter should look like 

    ``wsrep_cluster_address="gcomm://fuel-01:4567,fuel-02:4567"``

    * If ``wsrep_cluster_address`` is set correctly, run ``rm -f /var/lib/mysql/grastate.dat`` and then ``service mysql start`` on this node.


#.  Connect to any node with mysql and run ``show status like 'wsrep%';`` again.

    * ``wsrep_local_state_comment`` should finally change from "Donor/Synced" or other statuses to "Synced". 

    Time to sync may vary depending on the database size and connection speed.

    * ``wsrep_cluster_status`` should be "Primary" on both nodes. 

    Galera is a master-master replication cluster and every node becomes primary by default (i.e. master). 
    Galera also supports master-slave configuration for special purposes. 
    Slave nodes have the "Non-Primary" value for ``wsrep_cluster_status``.

    * ``wsrep_cluster_size`` should be "2", since we have just added one more node to the cluster.

    * ``wsrep_incoming_addresses`` should include the addresses of both started nodes.
 
    **Note:** 
    State transfer is a heavy operation not only on the joining node, but also on donor. 
    In particular state donor may be not able to serve client requests, or be plain slow.


#.  Repeat step 4 on all remaining controllers

    If all secondary controllers are started successfully and became synced and you do not plan to restart the cluster 
    in the nearest future, it is strongly recommended to change the ``wsrep`` configuration setting on the first controller.
 
    * Open file ``/etc/mysql/conf.d/wsrep.cnf``.
    * Set ``wsrep_cluster_address=`` to the same value (node list) that is used for every secondary controller.

    In case of OpenStack deployed by Fuel manifests with default settings (2 controllers), 
    on every operating controller this parameter should finally look like 

    ``wsrep_cluster_address="gcomm://fuel-01:4567,fuel-02:4567"`` 

    This step is important for future failures or maintenance procedures.
    In case Galera primary controller node is restarted with the empty "gcomm" value 
    (i.e. ``wsrep_cluster_address="gcomm://"``), it creates a new cluster and exits the existing cluster. 
    The existing cluster nodes may also stop receiving requests and the synchronization process to prevent data 
    de-synchronization issues.
  

    **Note:**
 
    Starting from mysql version 5.5.28_wsrep23.7 (Galera version 2.2), Galera cluster supports additional start mode. 
    Instead of setting ``wsrep_cluster_address="gcomm://"``, on the first node one can set the following URL 
    for cluster address:

    ``wsrep_cluster_address="gcomm://node1,node2:port2,node3?pc.wait_prim=yes"``,

    where ``nodeX`` is the name or IP address of one of available nodes, with optional port.

    Therefore, every Galera node may have the same configuration file with the list of all nodes. 
    It is designed to eliminate all configuration file changes on the first node after the cluster is started.

    After the nodes are started, with mysql one may set the ``pc.bootstrap=1`` flag to the node 
    which should start the new cluster and become the primary node.
    All other nodes should automatically perform initial synchronization with this new primary node. 
    This flag may be also provided for a single selected node via the ``wsrep.cnf`` configuration file as follows:

    ``wsrep_cluster_address="gcomm://node1,node2:port2,node3?pc.wait_prim=yes&pc.bootstrap=1"``

    Unfortunately, due to a bug in mysql init script (<https://bugs.launchpad.net/codership-mysql/+bug/1087368>), 
    the bootstrap flag is completely ignored in Galera 2.2 (wsrep_2.7). So, to start a new cluster, one should use 
    the old way with an empty ``gcomm://`` URL.
    All other nodes may have both the single node and multiple node list in the ``gcomm`` URL, 
    the bug affects only the first node - the one that starts the new cluster.
    Please note also that nodes with non-empty ``gcomm`` URL may start only if at least one of the nodes 
    listed in ``gcomm://node1,node2:port2,node3`` is already started and is available for initial synchronization.
    For every starting Galera node it is enough to have at least one working node name/address to get full 
    information about the cluster structure and to perform initial synchronization.
    Actually Fuel deployment manifests with default settings may set (or may not set!)

    ``wsrep_cluster_address="gcomm://"`` 

    on the primary node (first deployed OpenStack controller) and node list like

    ``wsrep_cluster_address="gcomm://fuel-01:4567,fuel-02:4567"`` 

    on every secondary controller. Therefore, it is a good idea to check these parameters after the deployment is finished.


    **Note:** 

    Galera cluster is a very democratic system. As it is a master-master cluster, 
    every primary node equals to other primary nodes.
    Primary nodes with the same sync state (same ``wsrep_cluster_state_uuid`` value) form the so called quorum - 
    the majority of primary nodes with the same ``wsrep_cluster_state_uuid``.
    Normally, one of the controllers gets a new commit, increases its ``wsrep_cluster_state_uuid`` value 
    and performs synchronization with other nodes.
    In case one of primary controllers fails, Galera cluster continues serving requests as long as the quorum exists.
    Exit of the primary controller from the cluster equals to a failure, since after exit this controller 
    has a new cluster ID and the ``wsrep_cluster_state_uuid`` value that is less than the same value on long-working nodes.
    So, 3 working primary controllers are the very minimal Galera cluster size. Recommended Galera cluster size is 
    6 controllers.
    Actually Fuel deployment manifests with default settings deploy non-recommended Galera configuration 
    with 2 controllers only. It is suitable for testing purposes, but not for production deployments.


**4. Continue existing cluster after failure**

Continuing Galera cluster after power breakdown or other types of failure basically consists of two steps: 
backing up every node and finding out the node with the most recent non-damaged replica.

* Helpful tip: add ``wsrep_provider_options="wsrep_on = off;"`` to the ``/etc/mysql/conf.d/wsrep.cnf`` configuration file.

After these steps simply perform the **Start Galera and create a new cluster** procedure, 
starting from this found node - the one with the most recent non-damaged replica.


Useful links
~~~~~~~~~~~~

* Galera documentation from Galera authors:

  * http://www.codership.com/wiki/doku.php

* Actual Galera and WSREP patch bug list and official Galera/WSREP bug tracker:

  * https://launchpad.net/codership-mysql
  * https://launchpad.net/galera

* One of recommended Galera cluster robust configurations:
 
  * http://wiki.vps.net/vps-net-features/cloud-servers/template-information/galeramysql-recommended-cluster-configuration/

* Why we use Galera:

  * http://openlife.cc/blogs/2011/july/ultimate-mysql-high-availability-solution

* Other questions (seriously, sometimes there is not enough info about Galera available in official Galera docs):

  * http://www.google.com
