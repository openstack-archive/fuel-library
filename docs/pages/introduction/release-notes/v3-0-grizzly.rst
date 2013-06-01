v3.0-grizzly
^^^^^^^^^^^^

**New Features in Fuel and Fuel Web 3.0**

* Support for OpenStack Grizzly
* Support for CentOS 6.4
* Deployment improvements
  
  * Deployment of Cinder as a standalone node
  * Users may now choose where to store Cinder volumes
  * User defined disk space allocation for the base OS, Cinder and Virtual Machines
  * Ability to add new compute nodes without redeployment of the whole environment
  * Swift installation occurs in a single pass instead of multiple passes

* Network configuration enhancements
 
  * Support for NIC bonding
  * Ability to map logical networks to physical interfaces 
  * Improved firewall module
 
**Support for OpenStack Grizzly**

OpenStack Grizzly is the seventh release of the open source software for building public, private, and hybrid clouds.  Fuel now supports deploying the Grizzly version of OpenStack in a variety of configurations including High Availability (HA).  For a list of known limitations, please refer to the Known Issues section below.
 
**Support for CentOS 6.4**

CentOS 6.4 can now be used as the base operating system for the Fuel master node, as well as the deployed slave nodes.
 
**Deployment Improvements**
 
* Deployment of Cinder as a standalone node / User choice

  Previously, Cinder could only be deployed onto a compute node.  Now, you may choose to deploy Cinder as a standalone node separate from a compute node.  Both options – either deployed with a compute node or standalone – are available.
