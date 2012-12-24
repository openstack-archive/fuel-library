Installation Instructions 
=========================


Network Setup
-------------

The current architecture assumes deployment with 3 network interfaces, for clarity. However, it can be tuned to support different scenarios, for example, deployment with only 2 NICs. The default set of interfaces is defined as follows:  

#. eth0 - management network for communication between Puppet master and Puppet clients, as well as PXE/TFTP/DHCP for Cobbler
    * every machine will have a static IP address there
    * you can configure network addresses/network mask according to your needs, but we will give instructions using the following network settings on this interface:
        * 10.0.0.100 for Puppet master
        * 10.0.0.101-10.0.0.103 for controller nodes
        * 10.0.0.104 for compute nodes
        * 255.255.255.0 network mask
        * in the case of VirtualBox environment, host machine will be 10.0.0.1

#. eth1 - public network, with access to Internet
    * we will assume that DHCP is enabled and every machine gets its IP address on this interface automatically through DHCP

#. eth2 - for communication between OpenStack VMs
    * without IP address
    * with promiscuous mode enabled

If you are on VirtualBox, create the following host-only adapters:

* VirtualBox -> Preferences...
    * Network -> Add host-only network (vboxnet0)
        * IPv4 address: 10.0.0.1
        * IPv4 mask: 255.255.255.0
        * DHCP server: disabled
    * Network -> Add host-only network (vboxnet1)
        * IPv4 address: 0.0.0.0
        * IPv4 mask: 255.255.255.0
        * DHCP server: disabled
    * If your host operating system is Windows, you need to fulfil an additional step of setting up IP address & network mask under "Control Panel -> Network and Internet -> Network and Sharing Center" for "Virtual Host-Only Network" adapter.
