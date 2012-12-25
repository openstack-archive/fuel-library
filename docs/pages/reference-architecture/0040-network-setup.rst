
Network Setup
-------------

The current architecture assumes the presence of 3 NIC cards in hardware, but can be customized to a different number of NICs (less or more):

* eth0
    * public network, floating IPs
* eth1
    * management network, communication with Puppet & Cobbler
* eth2
    * network for communication between OpenStack VMs, bridge interface (VLANs)

In multi-host networking mode, you can choose between FlatDHCPManager and VlanManager network managers in OpenStack.  Please see the figure below which illustrates all relevant nodes and networks.


.. image:: https://docs.google.com/drawings/pub?id=1XSmImw196Lzy03_Oe6louVH-3AszhSkuqo1mPVLw79I&w=800&h=542

