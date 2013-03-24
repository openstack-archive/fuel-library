.. _Swift-and-object-storage-notes:

Swift (object storage) notes
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

FUEL currently supports several ways to deploy the swift service:

* Swift absent

  By default, Glance uses the filesystem backend to store virtual machine images. In this case, you can use any of shared file systems Glance supports. 

* Swift compact

  In this mode the role of swift-storage and swift-proxy are combined with a nova-controller. Use it only for testing in order to save nodes; it's not suitable for production.

* Swift standalone

  In this case the Proxy service and Storage (account/container/object) services reside on separate nodes, with one proxy node and a minimum of three storage nodes.  (For a production cluster, a minimum of five nodes is recommended.)

Now let's look at performing an actual OpenStack installation using Fuel.

