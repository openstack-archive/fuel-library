.. toctree::
   :maxdepth: 2

Reference Architecture
======================

This reference architecture, combined with Cobbler & Puppet automation, allows you to easily deploy OpenStack in a highly available mode. It means that failure of a single service or even a whole controller machine will not affect your ability to control the cloud. High availability for OpenStack is provided by integrated open source components, including:

* keepalived
* HAProxy
* RabbitMQ
* MySQL/Galera

It’s important to mention that the entire reference architecture is based on active/active mode for all components. There are no active/standby elements, so the deployment can be easily scaled by adding new active nodes if/as needed, whether it’s controllers, compute, or storage.


Overview
--------

OpenStack services are interconnected by RESTful HTTP-based APIs and AMQP-based RPC messages. So, redundancy for stateless OpenStack API services is implemented through the combination of VIP management (keepalived) and load balancing (HAProxy). Stateful OpenStack components, such as state database and messaging server, rely on their respective active-active modes for high availability -- RabbitMQ uses built-in clustering capabilities, while the database uses MySQL/Galera replication.


.. image:: https://docs.google.com/drawings/pub?id=1pWuLe06byR1wkAuPcVEO0vLfFX9YSFIENAXru2OJ9ME&w=800&h=594


Logical Setup 
-------------


Controller Nodes
^^^^^^^^^^^^^^^^
Let’s take a closer look on how OpenStack deployment will look like and what will it take to achieve high availability for an OpenStack deployment:

* Every OpenStack cluster has multiple controller nodes in order to provide redundancy
* Every OpenStack controller is running keepalived which manages a single VIP for all controller nodes
* Every OpenStack controller is running HAProxy for HTTP and TCP load balancing of requests going to OpenStack API services, RabbitMQ and MySQL
* When the end users access OpenStack cloud using Horizon and/or REST API, the request goes to an alive controller node which currently holds VIP, and the connection gets terminated by HAProxy
* HAProxy performs load balancing, and it may very well send the current request to a service on different controller node. That includes services and components like nova-api, glance-api, keystone-api, nova-scheduler, Horizon, MySQL, and RabbitMQ
* Involved services and components have their own mechanisms for achieving HA
    * nova-api, glance-api, keystone-api and nova-scheduler are stateless services and do not require any special attention besides load balancing
    * Horizon, as a typical web application, requires sticky sessions to be enabled at the load balancer
    * RabbitMQ provides active/active high availability using mirrored queues
    * MySQL high availability is achieved through Galera active/active multi-master deployment


.. image:: https://docs.google.com/drawings/pub?id=1Hb3toPf7daEYuLAhBatMsIFIM3q0M5lWyCVNvgxAFAs&w=800&h=618


Compute Nodes
^^^^^^^^^^^^^

OpenStack compute need to “talk” to controller nodes and reach out to essential services such as RabbitMQ and MySQL. They use the same approach that provides redundancy to the end-users of Horizon and REST APIs, reaching out to controller nodes using VIP and going through HAProxy.

As for networking, we recommend deploying OpenStack in a “multi-host” mode, eliminating single point of failure when it comes to running nova-network service. In this configuration, nova-network service and metadata service provided by dnsmasq DHCP server run on every compute node in the cluster. Therefore, every compute node acts as a network controller and default gateway for all virtual servers from all tenants that run on this particular node.


.. image:: https://docs.google.com/drawings/pub?id=1qRRapVFy6YFw8huUmQk6qTXCUkJd3JGjDX_yQ-GnGnY&w=800&h=614


Storage Nodes
^^^^^^^^^^^^^

This reference architecture requires shared storage to be present in an OpenStack cluster. The shared storage will act as a backend for Glance, so that multiple glances instances running on controller nodes can store images on and retrieve images from it. Our recommendation is to deploy Swift and use it not only for storing VM images, but also for any other objects.


.. image:: https://docs.google.com/drawings/pub?id=19Z-GgvoKJCJyb9c2MML-ztB00tWZ0cSWmcbGArtF4_o&w=800&h=609



Cluster Sizing
--------------

This reference architecture is well suited for production-grade OpenStack deployments on medium and large scale, where you can afford to allocate several servers for your OpenStack controller nodes in order to build a fully redundant and highly available environment.

The absolute minimum requirement for a highly-available OpenStack deployment is 4 nodes. It includes:

* 3 controller nodes, combined with with storage
* 1 compute node


.. image:: https://docs.google.com/drawings/pub?id=1So4NbE1cLV0X-qDL5QPz6oobH3NHXVsmINmfTmirehk&w=800&h=465


If you want to run storage separately from controllers, you can do that as well raising the bar to 7 nodes:

* 3 controller nodes
* 3 storage nodes
* 1 compute node


.. image:: https://docs.google.com/drawings/pub?id=1BhMtVmCJV1VUf3OSIqgd4lac0_R6hliQT1jVGl-44-w&w=800&h=624


Of course, you have freedom in choosing how to deploy OpenStack based on the amount of available hardware you have, and based on your goals (whether you want a compute-oriented, or storage-oriented cluster).

For a typical OpenStack compute deployment, you can use this table as a high-level guidance to determine the number of controllers, compute, and storage nodes you should have:

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

The current architecture assumes presence of 3 NIC cards in hardware, but can be customized to different number of NICs (less, or more):

* eth0
    * public network, floating IPs
* eth1
    * management network, communication with Puppet & Cobbler
* eth2
    * network for communication between OpenStack VMs, bridge interface (VLANs)

In multi-host networking mode, you can choose between FlatDHCPManager and VlanManager network managers in OpenStack.  Please see the following figure which shows all relevant nodes and networks.


.. image:: https://docs.google.com/drawings/pub?id=1XSmImw196Lzy03_Oe6louVH-3AszhSkuqo1mPVLw79I&w=800&h=542

