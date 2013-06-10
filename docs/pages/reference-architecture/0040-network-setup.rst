
Network Architecture
^^^^^^^^^^^^^^^^^^^^


The current architecture assumes the presence of 3 NIC cards in
hardware, but can be customized to a different number of NICs (less,
or more).  In this case, let's consider a typical example of 3 NIC cards.
They're utilized as follows:


* **eth0**: the internal management network, used for communication with Puppet & Cobbler
* **eth1**: the public network, and floating IPs assigned to VMs
* **eth2**: the private network, for communication between OpenStack VMs, and the bridge interface (VLANs)


In the multi-host networking mode, you can choose between the
FlatDHCPManager and VlanManager network managers in OpenStack. The
figure below illustrates the relevant nodes and networks.

.. image:: https://docs.google.com/drawings/pub?id=11KtrvPxqK3ilkAfKPSVN5KzBjnSPIJw-jRDc9fiYhxw&w=810&h=1060

Lets take a closer look at each network and how its used within the
cluster.



Public Network
++++++++++++++

This network allows inbound connections to VMs from the outside world
(allowing users to connect to VMs from the Internet). It also allows
outbound connections from VMs to the outside world.



For security reasons, the public network is usually isolated from the
private network and internal (management) network. Typically, it's a
single C class network from your globally routed or private network
range.

To enable Internet access to VMs, the public network provides the
address space for the floating IPs assigned to individual VM instances
by the project administrator. Nova-network or Quantum services can
then configure this address on the public network interface of the
Network controller node. If the cluster uses nova-network, nova-
network uses iptables to create a Destination NAT from this address to
the fixed IP of the corresponding VM instance through the appropriate
virtual bridge interface on the Network controller node.



In the other direction, the public network provides connectivity to
the globally routed address space for VMs. The IP address from the
public network that has been assigned to a compute node is used as the
source for the Source NAT performed for traffic going from VM
instances on the compute node to Internet.



The public network also provides VIPs for Endpoint nodes, which are
used to connect to OpenStack services APIs.

Internal (Management) Network
+++++++++++++++++++++++++++++

The internal network connects all OpenStack nodes in the cluster. All
components of an OpenStack cluster communicate with each other using
this network. This network must be isolated from both the private and
public networks for security reasons.



The internal network can also be used for serving iSCSI protocol
exchanges between Compute and Storage nodes.



This network usually is a single C class network from your private,
non-globally routed IP address range.


Private Network
+++++++++++++++

The private network facilitates communication between each tenant's
VMs. Private network address spaces are part of the enterprise network
address space. Fixed IPs of virtual instances are directly accessible
from the rest of Enterprise network.



The private network can be segmented into separate isolated VLANs,
which are managed by nova-network or Quantum services.
