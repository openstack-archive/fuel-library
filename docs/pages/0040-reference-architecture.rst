Reference Architecture
======================

.. contents:: :local:

This reference architecture, combined with Cobbler & Puppet automation, allows you to easily deploy OpenStack in a highly available mode. It means that the failure of a single service or even a whole controller machine will not affect your ability to control the cloud. High availability for OpenStack is provided by integrated open source components, including:

* keepalived
* HAProxy
* RabbitMQ
* MySQL/Galera

It is important to mention that the entire reference architecture is based on the active/active mode for all components. There are no active/standby elements, so the deployment can be easily scaled by adding new active nodes if/as needed: controllers, compute nodes, or storage nodes.


.. include:: reference-architecture/0010-overview.rst
.. include:: reference-architecture/0020-logical-setup.rst
.. include:: reference-architecture/0030-cluster-sizing.rst
.. include:: reference-architecture/0040-network-setup.rst

