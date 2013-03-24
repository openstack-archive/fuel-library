
Installing & Configuring Puppet Master
--------------------------------------
Now that you know what you're going to install and where you're going to
install it, it's time to begin putting the pieces together. To do that,
you'll need to create the Puppet master and Cobbler servers, which will
actually provision and set up your OpenStack nodes.

Installing Puppet Master is a one-time procedure for the entire
infrastructure. Once done, Puppet Master will act as a single point of
control for all of your servers, and you will never have to return to
these installation steps again.

The deployment of the Puppet Master server -- named fuel-pm in these
instructions -- varies slightly between the physical and simulation
environments. In a physical infrastructure, fuel-pm must have a
network presence on the same network the physical machines will
ultimately PXE boot from. In a simulation environment fuel-pm only
needs virtual network (hostonlyif) connectivity.

The easiest way to create an instance of fuel-pm is to download the
Mirantis ISO from http://fuel.mirantis.com/your-downloads/

This ISO can be used to create fuel-pm on a physical or virtual
machine based on CentOS6.3x86_64minimal.iso. If for some reason you
can't use this ISO, follow the instructions in :ref:`Creating the Puppet master <Create-PM>` to create
your own fuel-pm, then skip ahead to :ref:`Configuring fuel-pm <Configuring-Fuel-PM>`.


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
infrastructure. For VirtualBox, this means creating three Host Only
interfaces, vboxnet0, vboxnet1, and vboxnet2, for the internal,
public, and private networks respectively.



Finally, we must assign network ranges to the internal, public, and private
networks, and ip addresses to fuel-pm, fuel-controllers, and fuel-compute nodes. For a real deployment using physical infrastructure you must work with your IT department to determine which IPs to use, but
for the purposes of this exercise we will assume the below network and
ip assignments:


#. 10.20.0.0/24: management or internal network, for communication between Puppet master and Puppet clients, as well as PXE/TFTP/DHCP for Cobbler
#. 192.168.0.0/24: public network, for the High Availability (HA) Virtual IP (VIP), as well as floating IPs assigned to OpenStack guest VMs
#. 10.20.1.0/24: private network, fixed IPs automatically assigned to guest VMs by OpenStack upon their creation 




Next we need to allocate a static IP address from the internal network
to eth0 for fuel-pm, and eth1 for the controller, compute, and (if necessary) quantum
nodes. For High Availability (HA) we must choose and assign an IP
address from the public network to HAProxy running on the controllers.
You can configure network addresses/network mask according to your
needs, but our instructions will assume the following network settings
on the interfaces:



#. eth0: internal management network, where each machine will have a static IP address

        * 10.20.0.100 for Puppet Master
        * 10.20.0.101-10.0.0.103 for the controller nodes
        * 10.20.0.110-10.0.0.126 for the compute nodes
        * 10.20.0.10 internal Virtual IP for component access
        * 255.255.255.0 network mask

#. eth1: public network

    * 192.168.0.10 public Virtual IP for access to the Horizon GUI (OpenStack management interface)

#. eth2: for communication between OpenStack VMs without IP address with promiscuous mode enabled.



If you are on VirtualBox, please create or make sure the following
hostonly adapters exist and are configured correctly:




If you are on VirtualBox, create the following adapters:

* VirtualBox -> Preferences...
    * Network -> Add HostOnly Adapter (vboxnet0)
        * IPv4 Address:  10.20.0.1
        * IPv4 Network Mask:  255.255.255.0
        * DHCP server: disabled
    * Network -> Add HostOnly Adapter (vboxnet1)
        * IPv4 Address:  10.20.1.1
        * IPv4 Network Mask:  255.255.255.0
        * DHCP server: disabled
    * Network -> Add HostOnly Adapter (vboxnet2)
        * IPv4 Address:  0.0.0.0
        * IPv4 Network Mask:  255.255.255.0
        * DHCP server: disabled

After creating this interface, reboot the host machine to make sure that
DHCP isn't running in the background.

Installing on Windows isn't recommended, but if you're attempting it,
you will also need to set up the IP address & network mask under
Control Panel > Network and Internet > Network and Sharing Center for the
Virtual HostOnly Network adapter.


Creating fuel-pm on a Physical Machine
--------------------------------------

If you plan to provision the Puppet master on hardware, you need to
create a bootable DVD or USB disk from the downloaded ISO, then make
sure that you can boot your server from the DVD or USB drive. 


Creating fuel-pm on a Virtual Machine
-------------------------------------

The process of creating a virtual machine to host Fuel in VirtualBox depends on
whether your deployment is purely virtual or consists of a virtual
fuel-pm controlling physical hardware. If your deployment is purely
virtual then Adapter 1 may be a Hostonly adapter attached to
vboxnet0, but if your deployment infrastructure consists of a virtual
fuel-pm controlling physical machines Adapter 1 must be a Bridged
Adapter, connected to whatever network interface of the host machine
is connected to your physical machines.

Start up VirtualBox and create a new machine as follows:

* Machine -> New...

    * Name: fuel-pm
    * Type: Linux
    * Version: Red Hat (32 or 64 Bit)
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



