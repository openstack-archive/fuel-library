Overview 
--------


Before you install any hardware or software, you must know what it is
you're trying to achieve. This section looks at the basic components of
an OpenStack infrastructure and organizes them into one of the more
common reference architectures. You'll then use that architecture as a
basis for installing OpenStack in the next section.



As you know, OpenStack provides the following basic services:


   * **Compute**: Compute servers are the workhorses of your installation; they're the servers on which your users' virtual machines are created. `Nova-scheduler` controls the life-cycle of these VMs.


   * **Networking**: Because an OpenStack cluster (virtually) always includes multiple servers, the ability for them to communicate with each other and with the outside world is crucial. Networking was originally handled by the `Nova-network` service, but it is slowly giving way to the newer `Quantum` networking service. Authentication and authorization for these transactions are handled by `Keystone`.


   * **Storage**: OpenStack provides for two different types of storage: block storage and object storage. Block storage is traditional data storage, with small, fixed-size blocks that are mapped to locations on storage media. At its simplest level, OpenStack provides block storage using `nova-volume`, but it is common to use `Cinder`.
  
     Object storage, on the other hand, consists of single variable-size objects that are described by system-level metadata, and you can access this capability using `Swift`.

     OpenStack storage is used for your users' objects, but it is also used for storing the images used to create new VMs. This capability is handled by `Glance`.



These services can be combined in many different ways. Out of the box,
Fuel supports the following deployment configurations:


Single node deployment
^^^^^^^^^^^^^^^^^^^^^^

In a production environment, you will never have a single-node
deployment of OpenStack, partly because it forces you to make a number
of compromises as to the number and types of services that you can
deploy. It is, however, extremely useful if you just want to see how
OpenStack works from a user's point of view. In this case, all of the
essential services run out of a single server:



.. image:: https://docs.google.com/drawings/d/1gGNYYayPAPPHgOYi98Dmebry4hP1SOGF2APXWzbnNo8/pub?w=767&h=413




Multi-node (non-HA) deployment (compact Swift)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

More commonly, your OpenStack installation will consist of multiple
servers. Exactly how many is up to you, of course, but the main idea
is that your controller(s) are separate from your compute servers, on
which your users' VMs will actually run. One arrangement that will
enable you to achieve this separation while still keeping your
hardware investment relatively modest is to house your storage on your
controller nodes.


Multi-node (non-HA) deployment (standalone Swift)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A more common arrangement is to provide separate servers for storage.
This has the advantage of reducing the number of controllers you must
provide; because Swift runs on its own servers, you can reduce the
number of controllers from three (or five, for a full Swift implementation) to one, if desired:


.. image:: https://docs.google.com/drawings/d/1nVEtfpNLaLV4EBKJQleLxovqMVrDCRT7yFWTYUQASB0/pub?w=767&h=413




Multi-node (HA) deployment (Compact)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Production environments typically require high availability, which
involves several architectural requirements. Specifically, you will
need at least three controllers, and
certain components will be deployed in multiple locations to prevent
single points of failure. That's not to say, however, that you can't
reduce hardware requirements by combining your storage, network, and controller
nodes:



.. image:: https://docs.google.com/drawings/d/1xLv4zog19j0MThVGV9gSYa4wh1Ma4MQYsBz-4vE1xvg/pub?w=767&h=413




Multi-node (HA) deployment (Compact Quantum)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Another way you can add functionality to your cluster without
increasing hardware requirements is to install Quantum on your
controller nodes. This architecture still provides high availability,
but avoids the need for a separate Quantum node:



.. image:: https://docs.google.com/drawings/d/1GYNM5yTJSlZe9nB5SHnlrqyMfVRdVh02OFLwXlz-itc/pub?w=767&h=413


Multi-node (HA) deployment (Standalone)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For larger production deployments, its more common to provide
dedicated hardware for storage and networking. This architecture still
gives you the advantages of high availability, but this clean
separation makes your cluster more maintainable by separating storage,
networking, and controller functionality:



.. image:: https://docs.google.com/drawings/d/1rJEZi5-l9oemMmrkH5UPjitQQDVGuZQ1KS0pPWTuovY/pub?w=769&h=594



Where Fuel really shines is in the creation of more complex
architectures, so in this document you'll learn how to use Fuel to
easily create a multi-node HA OpenStack cluster. To reduce the amount
of hardware you'll need to follow the installation in section 3,
however, the guide focuses on the Multi-node HA Compact 
architecture.



Lets take a closer look at the details of this deployment configuration.


