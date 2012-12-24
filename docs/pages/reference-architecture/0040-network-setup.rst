
Network Setup
-------------

The current architecture assumes the presence of 3 NIC cards in hardware, but can be customized to a different number of NICs (less, or more):

* eth0
    * management network, communication with Puppet & Cobbler
* eth1
    * public network, floating IPs
* eth2
    * network for communication between OpenStack VMs, bridge interface (VLANs)

In the multi-host networking mode, you can choose between FlatDHCPManager and VlanManager network managers in OpenStack.  Please see the figure below which illustrates all relevant nodes and networks.


.. image:: https://docs.google.com/drawings/pub?id=11KtrvPxqK3ilkAfKPSVN5KzBjnSPIJw-jRDc9fiYhxw&w=810&h=1060

Public Network
^^^^^^^^^^^^^^

This network allows inbound connections to VMs from the outside world (allowing users to connect to VMs from the Internet), as well as it allows outbound connections from VMs to the outside world:

* it provides address space for Floating IPs assigned to individual VM instances. Floating IP is assigned to the VM by project administrator. Nova-network or Quantum services configures this address on the public network interface of Network controller node. If nova-network is in use, then iptables are used to create Destination NAT from this address to Fixed IP of corresponding VM instance through the appropriate virtual bridge interface on the Network controller node
* it provides connectivity to the globally routed address space for VMs. IP address from Public network assigned to a compute node is used as source for SNAT performed for traffic going from VM instances on the compute node to Internet.

Public network also provides Virtual IPs (VIPs) for Endpoint node which are used to connect to OpenStack services APIs.

Public network is usually isolated from Private networks and Management network. Typically it's a single C class network from Customer's network range (globally routed or private range).

Internal (Management) Network
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Management network connects all OpenStack nodes in the cluster. All components of an OpenStack cluster communicate with each other using this network. This network must be isolated from Private and Public networks for security reasons.

Management network can also be used for serving iSCSI protocol exchange between Compute and Volume nodes.

This network usually is a single C class network from private IP address range (not globally routed).


Private Network
^^^^^^^^^^^^^^^

Private network facilicates communication between VMs of each tenant. Project network address spaces are part of enterprise network address space. Fixed IPs of virtual instances are directly accessible from the rest of Enterprise network. 

Private network can be segmented into separate isolated VLANs, which are managed by nova-network or Quantum services.
