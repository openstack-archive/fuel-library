.. _Swift-and-object-storage-notes:

Swift (object storage) notes
----------------------------

FUEL currently supports several ways to deploy the swift service:

* Swift absent

  The default backend that Glance uses to store virtual machine images is the filesystem backend.
  This simple backend writes image files to the local filesystem. 
  In this case, you can use any of shared file systems which are supported by the Glance. 

* Swift compact

  In this mode the role of swift-storage and swift-proxy combined with a nova-controller.
  Use it only for testing in order to save nodes but for production use is not really suitable.

* Swift standalone

  In this case the Proxy service and Storage (account/container/object) services reside on separate nodes.
  There is deployed one proxy node and three storage nodes.
  Three Storage nodes can be used initially, but a minimum of 5 is recommended for a production cluster.
