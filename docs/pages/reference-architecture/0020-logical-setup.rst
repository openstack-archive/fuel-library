
Logical Setup 
-------------


Controller Nodes
^^^^^^^^^^^^^^^^
Let us take a closer look at what OpenStack deployment looks like, and what it will take to achieve high availability for an OpenStack deployment:

* Every OpenStack cluster has multiple controller nodes in order to provide redundancy
* Every OpenStack controller is running keepalived which manages a single VIP for all controller nodes
* Every OpenStack controller is running HAProxy for HTTP and TCP load balancing of requests going to OpenStack API services, RabbitMQ, and MySQL
* When the end users access OpenStack cloud using Horizon and/or REST API, the request goes to a live controller node which currently holds VIP, and the connection gets terminated by HAProxy
* HAProxy performs load balancing, and it may very well send the current request to a service on a different controller node. That includes services and components like nova-api, glance-api, keystone-api, nova-scheduler, Horizon, MySQL, and RabbitMQ
* Involved services and components have their own mechanisms for achieving HA
    * nova-api, glance-api, keystone-api and nova-scheduler are stateless services and do not require any special attention besides load balancing
    * Horizon, as a typical web application, requires sticky sessions to be enabled at the load balancer
    * RabbitMQ provides active/active high availability using mirrored queues
    * MySQL high availability is achieved through Galera active/active multi-master deployment


.. image:: https://docs.google.com/drawings/pub?id=1Hb3toPf7daEYuLAhBatMsIFIM3q0M5lWyCVNvgxAFAs&w=800&h=618


Compute Nodes
^^^^^^^^^^^^^

OpenStack compute nodes need to "talk" to controller nodes and reach out to essential services such as RabbitMQ and MySQL. They use the same approach that provides redundancy to the end-users of Horizon and REST APIs, reaching out to controller nodes using VIP and going through HAProxy.

As for networking, we recommend deploying OpenStack in a "multi-host" mode, eliminating single point of failure when it comes to running the nova-network service. In this configuration, the nova-network service and metadata service provided by dnsmasq DHCP server run on every compute node in the cluster. Therefore, every compute node acts as a network controller and default gateway for all virtual servers from all tenants that run on this particular node.


.. image:: https://docs.google.com/drawings/pub?id=1qRRapVFy6YFw8huUmQk6qTXCUkJd3JGjDX_yQ-GnGnY&w=800&h=614


Storage Nodes
^^^^^^^^^^^^^

This reference architecture requires shared storage to be present in an OpenStack cluster. The shared storage will act as a backend for Glance, so that multiple glances instances running on controller nodes can store images on and retrieve images from it. Our recommendation is to deploy Swift and use it not only for storing VM images, but also for any other objects.


.. image:: https://docs.google.com/drawings/pub?id=19Z-GgvoKJCJyb9c2MML-ztB00tWZ0cSWmcbGArtF4_o&w=800&h=609

