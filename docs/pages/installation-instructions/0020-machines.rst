Infrastructure allocation and installation
------------------------------------------

The next step is to make sure that you have all of the required
hardware and software in place.


Software
^^^^^^^^

You can download the latest release of the Fuel ISO from http://fuel.mirantis.com/your-downloads/.

Alternatively, if you can't use the pre-built ISO, Mirantis also offers the Fuel Library as a tar.gz file downloadable from `Downloads <http://fuel.mirantis.com/your-downloads/>`_ section of the Fuel portal.  Using this file requires a bit more manual effort, but will yeild the same results as using the ISO.


Network setup
^^^^^^^^^^^^^

OpenStack requires a minimum of three distinct networks: internal (or
management), public, and private. The simplest and best mapping is to
assign each network to a different physical interface. However, not
all machines have three NICs, and OpenStack can be configured and
deployed with only two physical NICs, collapsing the internal and
public traffic onto a single NIC.



If you are deploying to a simulation environment, however, it makes
sense to just allocate three NICs to each VM in your OpenStack
infrastructure, one each for the internal, public, and private networks respectively.



Finally, we must assign network ranges to the internal, public, and private
networks, and ip addresses to fuel-pm, fuel-controllers, and fuel-compute nodes. For a real deployment using physical infrastructure you must work with your IT department to determine which IPs to use, but
for the purposes of this exercise we will assume the below network and
ip assignments:


#. 10.0.0.0/24: management or internal network, for communication between Puppet master and Puppet clients, as well as PXE/TFTP/DHCP for Cobbler. 
#. 192.168.0.0/24: public network, for the High Availability (HA) Virtual IP (VIP), as well as floating IPs assigned to OpenStack guest VMs
#. 10.0.1.0/24: private network, fixed IPs automatically assigned to guest VMs by OpenStack upon their creation 




Next we need to allocate a static IP address from the internal network
to eth0 for fuel-pm, and eth1 for the controller, compute, and (if necessary) quantum
nodes. For High Availability (HA) we must choose and assign an IP
address from the public network to HAProxy running on the controllers.
You can configure network addresses/network mask according to your
needs, but our instructions will assume the following network settings
on the interfaces:



#. eth0: internal management network, where each machine will have a static IP address

        * 10.0.0.100 for Puppet Master
        * 10.0.0.101-10.0.0.103 for the controller nodes
        * 10.0.0.110-10.0.0.126 for the compute nodes
        * 10.0.0.10 internal Virtual IP for component access
        * 255.255.255.0 network mask

#. eth1: public network

    * 192.168.0.10 public Virtual IP for access to the Horizon GUI (OpenStack management interface)

#. eth2: for communication between OpenStack VMs without IP address with promiscuous mode enabled.




Physical installation infrastructure
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The amount of hardware necessary for an installation depends on the
choices you have made above. This sample installation requires the
following hardware:

* 1 server to host both Puppet Master and Cobbler. The minimum configuration for this server is:

    * 32-bit or 64-bit architecture
    * 1+ CPU or vCPU for up to 10 nodes (2 vCPU for up to 20 nodes, 4 vCPU for up to 100 nodes)
    * 1024+ MB of RAM for up to 10 nodes (4096+ MB for up to 20 nodes, 8192+ MB for up to 100 nodes)
    * 16+ GB of HDD for OS, and Linux distro storage

* 3 servers to act as OpenStack controllers (called fuel-controller-01, fuel-controller-02, and fuel-controller-03). The   minimum configuration for a controller in Compact mode is:

    * 64-bit architecture
    * 1+ CPU
    * 1024+ MB of RAM (2048+ MB preferred)
    * 400+ GB of HDD

* 1 server to act as the OpenStack compute node (called fuel-compute-01). The minimum configuration for a compute node with Cinder deployed on it is:

    * 64-bit architecture
    * 2+ CPU, with Intel VTx or AMDV virtualization technology
    * 2048+ MB of RAM
    * 1+ TB of HDD

(If you choose to deploy Quantum on a separate node, you will need an
additional server with specifications comparable to the controller
nodes.)

Make sure your hardware is capable of PXE booting over the network from Cobbler. You'll also need each server's mac addresses.


For a list of certified hardware configurations, please `contact the
Mirantis Services team <http://www.mirantis.com/contact/>`_.

Virtual installation infrastructure
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For a virtual installation, you need only a single machine. You can get
by on 8GB of RAM, but 16GB will be better. 

To actually perform the
installation, you need a way to create Virtual Machines. This guide
assumes that you are using version 4.2.12 of VirtualBox, which you can download from

https://www.virtualbox.org/wiki/Downloads

Make sure to also install the Extension Pack.

You'll need to run VirtualBox on a stable host system. Mac OS 10.7.x,
CentOS 6.3+, or Ubuntu 12.04 are preferred; results in other operating 
systems are unpredictable.


Configuring VirtualBox
++++++++++++++++++++++

If you are on VirtualBox, please create or make sure the following
hostonly adapters exist and are configured correctly:

* VirtualBox -> File -> Preferences...

    * Network -> Add HostOnly Adapter (vboxnet0)

        * IPv4 Address:  10.0.0.1
        * IPv4 Network Mask:  255.255.255.0
        * DHCP server: disabled

    * Network -> Add HostOnly Adapter (vboxnet1)

        * IPv4 Address:  10.0.1.1
        * IPv4 Network Mask:  255.255.255.0
        * DHCP server: disabled

    * Network -> Add HostOnly Adapter (vboxnet2)

        * IPv4 Address:  0.0.0.0
        * IPv4 Network Mask:  255.255.255.0
        * DHCP server: disabled

In this example, only the first two adapters will be used, but you can choose to use the third to handle your storage network traffic.

After creating these interfaces, reboot the host machine to make sure that
DHCP isn't running in the background.

Installing on Windows isn't recommended, but if you're attempting it,
you will also need to set up the IP address & network mask under
Control Panel > Network and Internet > Network and Sharing Center for the
Virtual HostOnly Network adapter.



Creating fuel-pm 
++++++++++++++++

The process of creating a virtual machine to host Fuel in VirtualBox depends on
whether your deployment is purely virtual or consists of a physical or virtual
fuel-pm controlling physical hardware. If your deployment is purely
virtual then Adapter 1 may be a Hostonly adapter attached to
vboxnet0, but if your deployment infrastructure consists of a virtual
fuel-pm controlling physical machines, Adapter 1 must be a Bridged
Adapter, connected to whatever network interface of the host machine
is connected to your physical machines.

To create fuel-pm, start up VirtualBox and create a new machine as follows:

* Machine -> New...

    * Name: fuel-pm
    * Type: Linux
    * Version: Red Hat (64 Bit)
    * Memory: 2048 MB
    * Drive space: 16 GB HDD

* Machine -> Settings... -> Network

    * Adapter 1

	* Physical network
	        * Enable Network Adapter
	        * Attached to: Bridged Adapter
	        * Name: The host machine's network with access to the network on which the physical machines reside
	* VirtualBox installation
                * Enable Network Adapter
                * Attached to: Hostonly Adapter
                * Name: vboxnet0

    * Adapter 2

        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: eth0 (or whichever physical network is attached to the Internet)

* Machine -> Storage

    * Attach the downloaded ISO as a drive  

If you can't (or would rather not) install from the ISO, you can find instructions for installing from the Fuel Library in :ref:`Appendix A <Create-PM>`.



Creating the OpenStack nodes
++++++++++++++++++++++++++++




If you're using VirtualBox, you will need to create the corresponding
virtual machines for your OpenStack nodes. Follow these instructions
to create machines named fuel-controller-01, fuel-controller-02, fuel-
controller-03, and fuel-compute-01, but do not start them yet.



As you create each network adapter, click Advanced to expose and
record the corresponding mac address.




* Machine -> New...



    * Name: fuel-controller-01 (you will need to repeat these steps for fuel-controller-02, fuel-controller-03, and fuel-compute-01)
    * Type: Linux
    * Version: Red Hat (64 Bit)
    * Memory: 2048MB
    * Drive space: 8GB


* Machine -> Settings -> System 

    * Check Network in Boot sequence

* Machine -> Settings -> Storage

    * Controller: SATA

        * Click the Add icon at the bottom of the Storage Tree pane and choose Add Disk
        * Add a second VDI disk of 10GB for storage

* Machine -> Settings -> Network

    * Adapter 1

        * Enable Network Adapter
        * Attached to: Hostonly Adapter
        * Name: vboxnet0

    * Adapter 2

        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: eth0 (physical network attached to the Internet.  You can also use a gateway.)

    * Adapter 3

        * Enable Network Adapter
        * Attached to: Hostonly Adapter
        * Name: vboxnet1
        * Advanced -> Promiscuous mode: Allow All


It is important that hostonly Adapter 1 goes first, as Cobbler will
use vboxnet0 for PXE, and VirtualBox boots from LAN on the first
available network adapter.

The additional drive volume will be used as storage space by Cinder, and will be configured automatically by Fuel.



