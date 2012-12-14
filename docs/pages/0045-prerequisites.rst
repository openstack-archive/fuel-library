Prerequisites
=============

.. contents:: :local:

Networking Notes
----------------

Public Network Segment
~~~~~~~~~~~~~~~~~~~~~~

This network connects cloud clients to the cluster. It provides address space for Floating IPs assigned to individual instances. Floating IP is assigned to the VM by project administrator. Nova-network or Quantum services configures this address on the public network interface of Network controller node. Iptables are used then by nova-network to create Destination NAT from this address to Fixed IP of corresponding VM instance through the appropriate virtual bridge interface for the project on the Network controller.

Public network provides Virtual IPs (VIPs) for Endpoint node which are used to connect to OpenStack services APIs.

Public network provides connectivity to the globally routed address space for compute virtual instances. IP address from Public network assigned to Compute node is used as source for SNAT performed for traffic going from instances on the node to Internet.

Public network is usually isolated from Private networks and Management network.

Public/corporate network usually is a single C class network from Customer’s network range (globally routed or private range).

Management (Internal) Network Segment
~~~~~~~~~~~~~~~~~~~~~~~~

Management network connects all cluster nodes. Management network is used for exchange management data between components of the OpenStack cluster. This network must be isolated from Private and Public networks for security reasons.

Management network can also be used for serving iSCSI protocol exchange between Compute and Volume nodes.

This network usually is a single C class network from private IP address range (not globally routed).


Private Network Segment
~~~~~~~~~~~~~~~~~~~~~~~

Private network contains all project networks. Project network address spaces are part of enterprise network address space. Fixed IPs of virtual instances are directly accessible from the rest of Enterprise network. 

Private network is segmented into separate isolated VLANs (single VLAN per project) which managed by nova-network or Quantum services.

Routing of packets is provided by Compute nodes.

Cinder Notes
------------

Cinder is persistent storage management service. It was created to replace nova-volume service. 

You can use any existing block devices you want. Some devices can be created by cobbler or connected by yourself, e.g. as additional virtual disks if you are using VirtualBox in demo environment or by yourselves if you attach them as additional RAID, SAN volumes or so on.

Also you can leave this field blank and create LVM VolumeGroups by yourself on every controller node. Just create VolumeGroup "cinder-volumes" if you are using cinder or "nova-volumes" if you are using nova-volume (which is deprecated).

Example "site*.pp" manifests assume that you have the same collection of physical devices for cinder-volumes VolumeGroup. If it is not true for your environment, then put simple puppet conditional constructions into your site.pp.

Be careful and do not try to add block devices containing your operating system or any other useful data, as they will be destroyed after you allocate them to virtual machines.

