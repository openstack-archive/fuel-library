Reference Architecture
======================

.. contents:: :local:

This reference architecture, combined with Cobbler & Puppet automation, allows you to easily deploy OpenStack in a highly available mode. It means that the failure of a single service or even a whole controller machine will not affect your ability to control the cloud. High availability for OpenStack is provided by integrated open source components, including:

* keepalived
* HAProxy
* RabbitMQ
* MySQL/Galera

It is important to mention that the entire reference architecture is based on the active/active mode for all components. There are no active/standby elements, so the deployment can be easily scaled by adding new active nodes if/as needed: controllers, compute nodes, or storage nodes.


Overview
--------

OpenStack services are interconnected by RESTful HTTP-based APIs and AMQP-based RPC messages. So, redundancy for stateless OpenStack API services is implemented through the combination of VIP management (keepalived) and load balancing (HAProxy). Stateful OpenStack components, such as state database and messaging server, rely on their respective active-active modes for high availability -- RabbitMQ uses built-in clustering capabilities, while the database uses MySQL/Galera replication.

.. image:: https://docs.google.com/drawings/pub?id=1PzRBUaZEPMG25488mlb42fRdlFS3BygPwbAGBHudnTM&w=750&h=491

Logical Setup 
-------------

Controller Nodes
^^^^^^^^^^^^^^^^
Let us take a closer look at how OpenStack deployment will look and what it will take to achieve high availability for an OpenStack deployment:

* Every OpenStack cluster has multiple controller nodes in order to provide redundancy. To avoid the split-brain in Galera cluster (quorum-based system), it is strongly advised to plan at least 3 controller nodes
* Every OpenStack controller is running keepalived which manages a single VIP for all controller nodes
* Every OpenStack controller is running HAProxy for HTTP and TCP load balancing of requests going to OpenStack API services, RabbitMQ, and MySQL
* When the end users access OpenStack cloud using Horizon and/or REST API, the request goes to a live controller node which currently holds VIP, and the connection gets terminated by HAProxy
* HAProxy performs load balancing and it may very well send the current request to a service on a different controller node. That includes services and components like nova-api, glance-api, keystone-api, quantum-api, nova-scheduler, Horizon, MySQL, and RabbitMQ
* Involved services and components have their own mechanisms for achieving HA
    * nova-api, glance-api, keystone-api, quantum-api and nova-scheduler are stateless services that do not require any special attention besides load balancing
    * Horizon, as a typical web application, requires sticky sessions to be enabled at the load balancer
    * RabbitMQ provides active/active high availability using mirrored queues
    * MySQL high availability is achieved through Galera active/active multi-master deployment


.. image:: https://docs.google.com/drawings/pub?id=1aftE8Yes7CdVSZgZD1A82T_2GqL2SMImtRYU914IMyQ&w=869&h=855


Compute Nodes
^^^^^^^^^^^^^

OpenStack compute nodes need to "talk" to controller nodes and reach out to essential services such as RabbitMQ and MySQL. They use the same approach that provides redundancy to the end-users of Horizon and REST APIs, reaching out to controller nodes using VIP and going through HAProxy.


.. image:: https://docs.google.com/drawings/pub?id=16gsjc81Ptb5SL090XYAN8Kunrxfg6lScNCo3aReqdJI&w=873&h=801


Storage Nodes
^^^^^^^^^^^^^

This reference architecture requires shared storage to be present in an OpenStack cluster. The shared storage will act as a backend for Glance, so that multiple glance instances running on controller nodes can store images and retrieve images from it. Our recommendation is to deploy Swift and use it not only for storing VM images, but also for any other objects.


.. image:: https://docs.google.com/drawings/pub?id=1Xd70yy7h5Jq2oBJ12fjnPWP8eNsWilC-ES1ZVTFo0m8&w=777&h=778



Cluster Sizing
--------------

This reference architecture is well suited for production-grade OpenStack deployments on a medium and large scale when you can afford allocating several servers for your OpenStack controller nodes in order to build a fully redundant and highly available environment.

The absolute minimum requirement for a highly-available OpenStack deployment is to allocate 4 nodes:

* 3 controller nodes, combined with storage
* 1 compute node


.. image:: https://docs.google.com/drawings/pub?id=19Dk1qD5V50-N0KX4kdG_0EhGUBP7D_kLi2dU6caL9AM&w=767&h=413


If you want to run storage separately from controllers, you can do that as well raising the bar to 7 nodes:

* 3 controller nodes
* 3 storage nodes
* 1 compute node


.. image:: https://docs.google.com/drawings/pub?id=1xmGUrk2U-YWmtoS77xqG0tzO3A47p6cI3mMbzLKG8tY&w=769&h=594


Of course, you are free to choose how to deploy OpenStack based on the amount of available hardware and on your goals (whether you want a compute-oriented or storage-oriented cluster).

For a typical OpenStack compute deployment, you can use this table as a high-level guide to determine the number of controllers, compute, and storage nodes you should have:

=============  ===========  =======  ==============
# of Machines  Controllers  Compute  Storage
=============  ===========  =======  ==============
4-10           3            1-7      on controllers
11-40          3            5-34     3 (separate)
41-100         4            31-90    6 (separate)
>100           5            >86      9 (separate)
=============  ===========  =======  ==============

Network Setup
-------------

The current architecture assumes the presence of 3 NIC cards in hardware, but can be customized to a different number of NICs (less, or more):

* eth0
    * public network, floating IPs
* eth1
    * management network, communication with Puppet & Cobbler
* eth2
    * network for communication between OpenStack VMs, bridge interface (VLANs)

In the multi-host networking mode, you can choose between FlatDHCPManager and VlanManager network managers in OpenStack.  Please see the figure below which illustrates all relevant nodes and networks.


.. image:: https://docs.google.com/drawings/pub?id=11KtrvPxqK3ilkAfKPSVN5KzBjnSPIJw-jRDc9fiYhxw&w=820&h=1000

