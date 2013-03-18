.. _Install-OS-Using-Fuel:

Installing the OS using Fuel
----------------------------

Now you're ready to start creating the OpenStack servers themselves.
The first step is to let Fuel's Cobbler kickstart and preseed files
assist in the installation of operating systems on the target servers.


Initial setup
^^^^^^^^^^^^^

If you are using hardware, make sure it is capable of PXE booting over
the network from Cobbler. You'll also need each server's mac address.



If you're using VirtualBox, you will need to create the corresponding
virtual machines for your OpenStack nodes. Follow these instructions
to create machines named fuel-controller-01, fuel-controller-02, fuel-
controller-03, and fuel-compute-02, but do not start them yet.



As you create each network adapter, click Advanced to expose and
record the corresponding mac address.




* Machine -> New...



    * Name: fuel-controller-01 (you will need to repeat these steps for fuel-controller-02, fuel-controller-03, and fuel-compute-01)
    * Type: Linux
    * Version: Red Hat (64 Bit)



* Machine -> System -> Motherboard...



    * Check Network in Boot sequence



* Machine -> Settings... -> Network



    * Adapter 1



        * Enable Network Adapter
        * Attached to: Hostonly Adapter
        * Name: vboxnet0



    * Adapter 2



        * Enable Network Adapter
        * Attached to: Internal
        * Name: vboxnet1
        * Advanced -> Promiscuous mode: Allow All



    * Adapter 3



        * Enable Network Adapter
        * Attached to: Internal
        * Name: vboxnet2
        * Advanced -> Promiscuous mode: Allow All



    * Adapter 4



        * Enable Network Adapter
        * Attached to: NAT



* Machine -> Settings -> Storage



    * Controller: SATA



        * Click the Add icon at the bottom of the Storage Tree pane
        * Add a second VDI disk of 10GB for storage








It is important that hostonly Adapter 1 goes first, as Cobbler will
use vboxnet0 for PXE, and VirtualBox boots from LAN on the first
available network adapter.



Adapter 4 is not strictly necessary, and can be thought of as an
implementation detail. Its role is to bypass a limitation of Hostonly
interfaces, and simplify internet access from the VM. It is possible
to accomplish the same without using Adapter 4, but it requires
bridged adapters or manipulating the iptables routes of the host, so
using Adapter 4 is much easier.

Also, the additional drive volume will be used as storage space by Cinder, and configured later in the process.



Installing OS on the nodes using Cobbler
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that Cobbler has the correct configuration, the only thing you
need to do is to PXE-boot your nodes. This means that they will boot over the network, with
DHCP/TFTP provided by Cobbler, and will be provisioned accordingly,
with the specified operating system and configuration.



In case of VirtualBox, start each virtual machine (fuel-controller-01,
fuel-controller-02, fuel-controller-03, fuel-compute-01) as follows:




#. Start the VM.
#. Press F12 immediately and select l (LAN) as a bootable media.
#. Wait for the installation to complete.
#. Log into the new machine using root/r00tme.
#. Check that networking is set up correctly and the machine can reach the Puppet Master and package repositories::

    ping fuel-pm.your-domain-name.com
    ping download.mirantis.com

If you're unable to ping outside addresses, add the fuel-pm server as a default gateway::

    route add default gw 10.20.0.10

**It is important to note** that if you use VLANs in your network
configuration, you always have to keep in mind the fact that PXE
booting does not work on tagged interfaces. Therefore, all your nodes,
including the one where the Cobbler service resides, must share one
untagged VLAN (also called native VLAN). You can use the
dhcp_interface parameter of the cobbler::server class to bind the DHCP
service to a certain interface.


.. _create-the-XFS-partition:

Create the XFS partition
^^^^^^^^^^^^^^^^^^^^^^^^

The last step before installing OpenStack is to prepare the partitions
on which Swift and Cinder will store their data. Later versions of
Fuel will do this for you, but for now, manually prepare the volume by
fdisk and initialize it.  To do that, follow these steps:




#. Create the partition itself::




    fdisk /dev/sdb
    n(for new)
    p(for partition)
    <enter> (to accept the defaults)
    <enter> (to accept the defaults)
    w(to save changes)




#. Initialize the XFS partition::




    mkfs.xfs -i size=1024 -f /dev/sdb1




#. For a standard swift install, all data drives are mounted directly under /srv/node, so first create the mount point::




    mkdir -p /srv/node/sdb1




#. Finally, add the new partition to fstab so it mounts automatically, then mount all current partitions::




    echo "/dev/sdb1 /srv/node/sdb1 xfs
    noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
    mount -a

