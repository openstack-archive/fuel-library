Release Notes for Fuel™ and Fuel™ Web Version 3.0
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

June 6, 2013

Mirantis, Inc. is releasing version 3.0.1 of the Fuel™ Library and Fuel™ Web products.  This is a `cumulative` maintenance release to the previously available version 3.0.  It contains the complete distribution of version 3.0 as well as additional enhancements and defect fixes. Customers are strongly recommended to install version 3.0.1.

These release notes supplement the product documentation and list enhancements, resolved issues and known issues.  Issues addressed specifically in version 3.0.1 will be clearly marked. 

 * :ref:`what-is-fuel`
 * :ref:`what-is-fuel-web`
 * :ref:`new-features`
 * :ref:`resolved-issues`
 * :ref:`known-issues`
 * :ref:`get-products`
 * :ref:`contact-support`


.. _what-is-fuel:


What is Fuel™?
~~~~~~~~~~~~~~
 
Fuel™ is the ultimate OpenStack Do-it-Yourself Kit. Purpose built to assimilate the hard-won experience of our services team, it contains the tooling, information, and support you need to accelerate time to production with OpenStack cloud.  Fuel is designed to work with Puppet configuration management software, using Cobbler for bare metal provisioning.   Fuel includes all core OpenStack components including Nova, Glance, Horizon, Swift, Keystone, Quantum and Cinder plus Open source packages for components required to support High Availability deployment configurations, including Galera, keepalived, and HA Proxy.
 

.. _what-is-fuel-web:


What is Fuel™ Web?
~~~~~~~~~~~~~~~~~~
 
Fuel™ Web is simplified way to deploy OpenStack with Fuel Library of scripts. If you are familiar with tools like Cobbler and Puppet and want maximum flexibility in your deployment, you can use the command-line capabilities of the Fuel Library to install OpenStack. However, if you want a streamlined, graphical console experience, you can install OpenStack using Fuel Web. It uses the same exact underlying scripts from Fuel Library, but offers a more user-friendly experience for deploying and managing OpenStack environments.
 

.. _new-features:


New Features in Fuel and Fuel Web 3.0.x
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 * Support for OpenStack Grizzly
 * Deployment improvements

   * Fuel 

     * Deployment of CentOS 6.4
     * Deployment of Cinder on standalone nodes
     * User defined disk space allocation for the base OS, Cinder and VMs
     * Add new nodes without redeployment 
     * Updated Oracle VirtualBox® deployment scripts

   * Fuel Library Only

     * Swift installation occurs in a single pass instead of multiple passes
     * Users may now choose where to store Cinder volumes

 * Network configuration enhancements

   * Fuel 

     * Partition networks across multiple network interface cards
     * Mapping of logical networks to physical interfaces
     * Define multiple IP ranges for public and floating networks
     * Security improvements

   * Fuel Library Only

     * Support for NIC bonding
     * Improved firewall module
 
**Support for OpenStack Grizzly**

  `OpenStack Grizzly <http://www.openstack.org/software/grizzly/>`_ is the seventh release of the open source software for building public, private, and hybrid clouds.  Fuel and Fuel Web now both feature support for deploying clusters using the Grizzly version of OpenStack, including deployment of a new nova-conductor service. Deployments can be done in a variety of configurations including High Availability (HA) mode.

  For a list of known limitations, please refer to the Known Issues section below.

 
.. _deployment-improvements:


Deployment Improvements
~~~~~~~~~~~~~~~~~~~~~~~
 
**Deployment of CentOS 6.4**

  CentOS 6.4 is now used as the base operating system for the Fuel master node as well as the deployed slave nodes when deploying via Fuel Web.  It is also the Operating System included in the Fuel Library ISO.
  Red Hat Enterprise Linux continues to be an available choice when deploying through the Fuel Library CLI.  Support for Ubuntu® is expected in a near future release.

**Deployment of Cinder from Fuel Web**

  This release introduces the ability to deploy Cinder on a set of standalone nodes from Fuel Web.  

**User defined disk space allocation**

  Previously, deployments created using Fuel Web used all allocated space on a defined hard drive (virtual or physical).  You may now in Fuel Web define the amount of disk space you want to use for each component on a given node.  For example, you may wish to define that more space be utilized by Cinder and less space be used for the remaining needs of the base system.
 
**Ability to add new nodes without redeployment**

  In previous releases of Fuel Web, to add a node you had to tear down the deployed OpenStack environment and rebuild it with the new configuration.  Now, you can choose to add a new compute or Cinder node without having to redeploy the entire environment.  The node will be deployed, it will automatically be pointed to RabbitMQ and MySQL and it will start receiving messages from scheduler.  Please see the Known Issues section for limitations on this feature.
 
**Updated VirtualBox scripts**

  The Fuel Web Virtualbox scripts provided for convenient creation of a small demo or POC cloud have been updated to more closely resemble a production environment.  Each virtual machine created by the scripts will have 3 disks and 3 network cards, which can be then configured in Fuel Web.

**Swift Installation in a single pass**

  During the deployment of Swift from the Fuel Library CLI, users were previously required to run Puppet against the Swift node several times to successfully complete a deployment. This requirement has been removed and you can now deploy Swift nodes in a single operation.  This reduces the deployment time for High Availability configurations.
  
**User choice of Cinder deployment**

  Previously, Cinder could only be deployed on a compute or controller node when utilizing the Fuel Library CLI.  Now, you may choose to deploy Cinder as a standalone node or deployed with a compute or controller node.


.. _net-config-improvements:


Network Configuration Improvements
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
**Partition networks across multiple network interface cards**

  Fuel Web now recognizes when multiple network interfaces are present on a node and enable usage of each NIC independently during network configuration.

**Mapping of logical networks to physical interfaces**

  Already available through Fuel, mapping of logical networks allows you to specify that a given virtual network be run only on a chosen physical interface.  This ability is now provided as an option within Fuel Web.

**Define multiple IP ranges for public and floating networks**

  Previously Fuel Web assumed that the gateway is always the first IP in the public network.  Users can now define multiple IP ranges for public and floating networks, and specify public gateway IP addresses. It is also possible to specify floating IPs one by one.

**Security improvements**

    In the OpenStack settings tab user can provide a SSH public key for nodes. In this case, remote access is restricted to use only ssh public key authentication for slave nodes. In addition, the Fuel Web master node root password can be changed with the “passwd” command.

**NIC bonding**

 NIC bonding is the ability to combine multiple network interfaces together to increase throughput beyond what a single connection could sustain, and to provide redundancy in case one of the links fails.  This configuration is now supported by the Fuel Library.  This enables, for example, use of switches that utilize the Link Aggregation Control Protocol (LACP).  This is available through the Fuel Library CLI but not when using Fuel Web.

**Improved firewall module**

  Fuel provides a basic firewall module during the deployment of an OpenStack environment.   An upgraded module is now included that allows a greater capability to manage and configure IP tables.  These configurations are done automatically by Fuel and do not require you to make any additional changes to the Fuel Library scripts to take advantage of this new module.

  
.. _resolved-issues:


Resolved Issues in Fuel and Fuel Web 3.0
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Ability to remove offline nodes**

  In the previous release if a node was powered off, it was impossible to remove the entire environment or remove an offline node from it. This limitation is now resolved.

**Networks restricted to 8 bit netmasks**

  Fuel and Fuel Web now work properly with networks utilizing a netmask larger or smaller than 8 bits (i.e. x.x.x.x/24).

**Duplicate entries in /var/lib/cobbler/cobbler_hosts**

  When deploying nodes, an entry in /var/lib/cobbler/cobbler_hosts is created with a different IP address for each physical interface (regardless of whether cable is connected or not). This causes deployment to fail because RabbitMQ appears to be down on the controller (even though it's not) because the wrong IP is returned from DNS.

**Log files grow too quickly**

  In the previous release, logging of each API was performed to the same log file as all other messages. Nodes agents sent data to the API every minute or so and these messages were logged also. Because of this, the log became non-readable and increased in size very quickly. 

  Fuel Web now separates log files - one for API calls, one for HTTP request/response, and another for static requests.  This makes each log file more readable and keeps each log file from growing in size as quickly.

**Design IP ranges for public/floating nets instead of simple CIDR**

  This issue has been resolved through the implementation of the more flexible IP parameters in Fuel Web.

**Deployment fails when nodes have drives greater than 2TB**

  Previously, the Cobbler snippet for partitioning the disk did not properly set the disk label to GPT to support partitions greater than 2TB. This has now been corrected.

  
.. _other-resolved-issues:


Other resolved issues
~~~~~~~~~~~~~~~~~~~~~

  * A Cobbler error no longer occurs when deploying a previously removed node. 
  * A better validation of puppet status has addressed a “Use failed_to_restart” error in the last_run_summary of a puppet run
  * Large RAM sizes (e.g. 1 Tb) are now correctly handled
  * Removal of nodes is handled much better
  * Special characters are now correctly handled in OpenStack passwords
  * Corrected a situation where puppet would not attempt a retry after the error “Could not request certificate: Error 400 on SERVER: Could not find certificate request for [hostname].tld”
  * Fixed simultaneous operations to ensure that threads in astute are safe
  * Nodes with multiple NICs can now boot normally via cobbler 

.. _resolved-in-301:
  
Resolved issues in Fuel and Fuel Web 3.0.1
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Support for CCISS controllers**

  In some cases, the hard drives on target nodes were not detected during deployment because the nodes utilized a non-standard CCISS hard drive controller.  This situation has been resolved.  The target nodes can now use CCISS HD controllers and the hard drives will be recognized during deployment.

**Increased timeout during provisioning**

  On occasion, the deployment would fail due to a timeout while deploying the OS, especially for Cinder and Compute nodes with high capacity hard drives.  This is because the process to format the hard drives took longer than the timeout value.  This has been corrected by increasing the timeout value.

**SSL certificate error**

  Sometimes, puppet would produce an error stating “Failed to generate additional resources using 'eval_generate: Error 400 on SERVER”.  This issue has been corrected.

**Recognizing network interfaces that start with em instead of eth**

  When a NIC is embedded in the motherboard, some operating systems will use the prefix of ``em`` (meaning “embedded”) instead of ``eth``.  Fuel previously had an issue installing onto systems where the NIC used a prefix of em.  This has now been corrected.

**Installing Fuel Web onto a system with multiple CD drives**

  The installation script for Fuel Web is designed to mount ``/dev/cdrom`` and copy files to the system. When multiple CD drives exist on a system, the ``/dev/cdrom`` symbolic link does not always point to the expected device.  The scripts have been corrected to work properly in this scenario.

**Sufficient disk space for Glance when using defaults**

  Previously in Fuel Web, if the a controller node is deployed with the default disk configuration, only a small amount of space was allocated to the OS volume (28GB on a 2TB drive for instance). This limited the number of images that could be stored in Glance.   All available disk space is now allocated by default.  This default can be changed by selecting the Disk Configuration button when viewing the details of a node prior to deployment.

**Logical volume for the base operating system properly allocated**

  In previous releases, Fuel Web improperly allocated only a small percentage of the logical volume for the base operating system when a user requested that the entire volume be used for the base system.  Previously, this situation had to be resolved manually.  This issue has now been corrected and Fuel Web will properly allocate all of the available disk space for the base system when requested to do so. 

**Creating a Cinder volume from a Glance image**

  Previously, in a simple deployment you couldn’t create a Cinder volume from a Glance image. This was because the ``glance_host`` parameter was not set in ``cinder.conf`` and the default is ``localhost``.  The ``glance_host`` parameter is now set to the controller IP.

**Auto-assigning floating IP addresses**

  Previously in Fuel Web, even when a user enabled auto-assigning of floating IP addresses in the OpenStack settings tab, the feature still was not enabled and user had to manually associate floating IP addresses to instances.  Fuel Web now correctly assigns the floating IP addresses to instances when the option is enabled.

**Floating IP address range**

  In some isolated cases in the previous releases, Fuel would create only one floating IP address instead of a specified range defined by the user.  This issue has been resolved and Fuel will now properly create all of the floating IP addresses in the requested range.

**Adding users to multiple projects in Horizon**

  Previously, when adding a user to multiple projects in Horizon, only the first project was accessible.  There was no drop-down for selecting the other assigned projects.  This could lead to users, especially the admin user, being assigned to another projects as a member only - thus losing admin access to Horizon.  This issue has now been resolved and all of the projects are now visible when adding a user in Horizon.

**Time synchronization issues no longer lead to error condition**

  From time to time ntpd may fail to synchronize and when this happens, the offset gets progressively larger until it resets itself and starts the cycle again of getting further out of synchronization.  This issue could lead to an error condition within mCollective.  This issue has been addressed by increasing the Time-to-Live (TTL) value for mCollective and setting the panic threshold for NTP to zero.

**Deployment on small capacity hard drives using Fuel Web**

  In previous releases, Fuel Web would produce an error when trying to deploy OpenStack components onto nodes with hard drives less than 13GB.  Fuel Web now calculates the minimum size base on multiple factors including os size, boot size and swap size (which itself is calculated based on available RAM).  However, Mirantis still recommends a minimum hard drive size of 15GB if possible.

  

.. _known-issues:


Known Issues in Fuel and Fuel Web 3.0.x
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Support for OpenStack Grizzly**

  The following improvements in Grizzly are not currently supported directly by Fuel:

  * Nova Compute

    * Cells
    * Availability zones
    * Host aggregates

  * Neutron (formerly Quantum)

    * LBaaS (Load Balancer as a Service)
    * Multiple L3 and DHCP agents per cloud

  * Keystone
    
    * Multi-factor authentication
    * PKI authentication

  * Swift
    
    * Regions
    * Adjustable replica count
    * Cross-project ACLs

  * Cinder

    * Support for FCoE
    * Support for LIO as an iSCSI backend
    * Support for multiple backends on the same manager

  * Ceilometer
  * Heat
  
  It is expected that these capabilities will be supported in a future release of Fuel.

  In addition, support for High Availability of Quantum on CentOS or Red Hat Enterprise Linux (RHEL) is not available due to a imitation within the CentOS kernel.  It is expected that this issue will addressed by a patch to CentOS and RHEL in late 2013. 

**Ability to add new nodes without redeployment**

It’s possible to add new compute and Cinder nodes to an existing OpenStack environment. However, this capability can not be used yet to deploy additional controller nodes in HA mode.

**Ability to map logical networks to physical interfaces**

It is not possible to map logical OpenStack networks to physical interfaces without using  VLANs. Even if there is just one L3 network, you will still be required to use a VLAN. This limitation only applies to Fuel Web; the Fuel Library does not have any such limitation.

**Other Limitations:**

  * Swift in High Availability mode must use loopback devices.
  * In Fuel Web, the size for Swift is hard coded to be 10Gb.  If you need to change this, please contact support; they can help modify this value.
  * When using Fuel Web, IP addresses for slave nodes (but not the master node) are assigned via DHCP during PXE booting from the master node.  Because of this, even after installation, the Fuel Web master node must remain available and continue to act as a DHCP server.
  * When using Fuel Web, the floating VLAN and public networks must use the same L2 network.  In the UI, these two networks are locked together, and can only run via the same physical interface on the server.
  * Fuel Web creates all networks on all servers, even if it they not required by a specific role (e.g. A Cinder node will have VLANs created and addresses obtained from the public network)
  * Some of OpenStack services listen on all interfaces, which may be detected and reported by security audits or scans.  Please discuss this issue with your security administrator if it is of concern in your organization.
  * The provided scripts that enable Fuel Web to be automatically installed on VirtualBox will create separated host interfaces. If a user associates logical networks to different physical interfaces on different nodes, it will lead to network connectivity issues between OpenStack components.  Please check to see if this has happened prior to deployment by clicking on the “Verify Networks” button on the networking tab.
  * The networks tab was redesigned to allow the user to provide IP ranges instead of CIDRs, however not all user input is properly verified. Entering a wrong wrong value may cause failures in deployment.
  * Quantum Metadata API agents in High Availability mode are only supported for compact and minimal scenarios if network namespaces (netns) is not used.
  * The Quantum namespace metadata proxy is not supported unless netns is used.
  * Quantum multi-node balancing conflicts with pacemaker, so the two should not be used together in the same environment.
  * In order for Virtual machines to have access to internet and/or external networks you need to set the floating network prefix and public_address so that they do not intersect with the network external interface to which it belongs. This is due to specifics of how Quantum sets Network Address Translation (NAT) rules and a lack of namespaces support in CentOS 6.4. 
  * The ``Total Space`` displayed in the ``Disk Configuration`` screen may be slightly larger than what is actually available.  Either choose “use all unallocated space” or enter a number significantly lower than the displayed value when modifying volume groups.

.. _get-products:


How to obtain the products
~~~~~~~~~~~~~~~~~~~~~~~~~~

**Fuel**

The first step in installing Fuel is to download the version appropriate for your environment.

To make your installation easier, we also offer a pre-built ISO for installing the master node with Puppet Master and Cobbler. You can mount this ISO in a physical or VirtualBox machine in order to easily create your master node. (Instructions for performing this step without the ISO are given in Appendix A of the documentation.)

The master node ISO, along with other Fuel releases, is available in the `Downloads <http://fuel.mirantis.com/your-downloads>`_ section of the Fuel portal.

**Fuel Web**

Fuel Web is distributed as a self-contained ISO that, once downloaded, does not require Internet access to provision OpenStack nodes.  This ISO is available in the `Fuel Web Download <http://fuel.mirantis.com/your-downloads>`_ section of the Fuel Portal.  Here you will also find the Oracle VirtualBox scripts to enable quick and easy deployment of a multi-node OpenStack cloud for evaluation purposes.


.. _contact-support:


Contacting Support
~~~~~~~~~~~~~~~~~~

You can contact support online, through E-mail or via phone.  Instructions on how to use any of these contact options can be found here: https://mirantis.zendesk.com/home.





To learn more about how Mirantis can help your business, please visit http://www.mirantis.com.

Mirantis, Fuel, the Mirantis logos and other Mirantis marks are trademarks or registered trademarks of Mirantis, Inc. in the U.S. and/or certain other countries.  Red Hat Enterprise Linux is a registered trademark of  Red Hat, Inc.  Ubuntu is a registered trademark of Canonical Ltd. VirtualBox is a registered trademark of Oracle Corporation.  All other registered trademarks or trademarks belong to their respective companies.  © 2013 Mirantis, Inc.  All rights reserved.
