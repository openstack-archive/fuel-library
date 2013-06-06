Release Notes for Fuel™ and Fuel™ Web Version 3.0
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

June 6, 2013

Mirantis, Inc. is releasing version 3.0 of the Fuel™ Library and Fuel™ Web products.  These release notes supplement the product documentation and list enhancements, resolved issues and known issues in this version. 

 * What is Fuel™?
 * What is Fuel™ Web?
 * New Features in Fuel™ and Fuel™ Web 3.0
 * Resolved Issues in Fuel™ and Fuel™ Web 3.0
 * Known Issues in Fuel™ and Fuel™ Web 3.0
 * How to obtain the products
 * Contacting Support

What is Fuel?
~~~~~~~~~~~~~
 
Fuel™ is the ultimate OpenStack Do-it-Yourself Kit. Purpose built to assimilate the hard-won experience of our services team, it contains the tooling, information, and support you need to accelerate time to production with OpenStack cloud.  Fuel is designed to work with Puppet configuration management software, using Cobbler for bare metal provisioning.   Fuel includes all core OpenStack components including Nova, Glance, Horizon, Swift, Keystone, Quantum and Cinder plus Open source packages for components required to support High Availability deployment configurations, including Galera, keepalived, and HA Proxy.
 
What is Fuel™ Web?
~~~~~~~~~~~~~~~~~~
 
Fuel™ Web is simplified way to deploy OpenStack with Fuel Library of scripts. If you are familiar with tools like Cobbler and Puppet and want maximum flexibility in your deployment, you can use the command-line capabilities of the Fuel Library to install OpenStack. However, if you want a streamlined, graphical console experience, you can install OpenStack using Fuel Web. It uses the same exact underlying scripts from Fuel Library, but offers a more user-friendly experience for deploying and managing OpenStack environments.
 
New Features in Fuel and Fuel Web 3.0
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
 

Deployment Improvements
~~~~~~~~~~~~~~~~~~~~~~~
 
**Deployment of CentOS 6.4**
  CentOS 6.4 is now used as the base operating system for the Fuel master node as well as the deployed slave nodes when deploying via Fuel Web.  It is also the Operating System included in the Fuel Library ISO.
  Red Hat Enterprise Linux continues to be an available choice when deploying through the Fuel Library CLI.  Support for Ubuntu® is expected in a near future maintenance release.

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

Known Issues in Fuel and Fuel Web 3.0
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Support for OpenStack Grizzly**

  The following improvements in Grizzly are not currently supported directly by Fuel:

  * Nova Compute

    * Cells
    * Availability zones
    * Host aggregates

  * Quantum

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

How to obtain the products
~~~~~~~~~~~~~~~~~~~~~~~~~~

**Fuel**
The first step in installing Fuel is to download the version appropriate for your environment.

To make your installation easier, we also offer a pre-built ISO for installing the master node with Puppet Master and Cobbler. You can mount this ISO in a physical or VirtualBox machine in order to easily create your master node. (Instructions for performing this step without the ISO are given in Appendix A of the documentation.)

The master node ISO, along with other Fuel releases, is available in the `Downloads <http://fuel.mirantis.com/your-downloads>`_ section of the Fuel portal.

**Fuel Web**
Fuel Web is distributed as a self-contained ISO that, once downloaded, does not require Internet access to provision OpenStack nodes.  This ISO is available in the `Fuel Web Download <http://fuel.mirantis.com/your-downloads>`_ section of the Fuel Portal.  Here you will also find the Oracle VirtualBox scripts to enable quick and easy deployment of a multi-node OpenStack cloud for evaluation purposes.

Contacting Support
~~~~~~~~~~~~~~~~~~

You can contact support online, through E-mail or via phone.  Instructions on how to use any of these contact options can be found here: https://mirantis.zendesk.com/home.





To learn more about how Mirantis can help your business, please visit http://www.mirantis.com.
Mirantis, Fuel, the Mirantis logos and other Mirantis marks are trademarks or registered trademarks of Mirantis, Inc. in the U.S. and/or certain other countries.  Red Hat Enterprise Linux is a registered trademark of  Red Hat, Inc.  Ubuntu is a registered trademark of Canonical Ltd. VirtualBox is a registered trademark of Oracle Corporation.  All other registered trademarks or trademarks belong to their respective companies.  © 2013 Mirantis, Inc.  All rights reserved.
