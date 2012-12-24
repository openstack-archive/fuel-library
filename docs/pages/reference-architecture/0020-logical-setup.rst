
Logical Setup 
-------------

Controller Nodes
^^^^^^^^^^^^^^^^
Let us take a closer look at what OpenStack deployment looks like, and what it will take to achieve high availability for an OpenStack deployment:

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
