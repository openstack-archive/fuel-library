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
        * Attached to: Hostonly Adapter
        * Name: vboxnet1



    * Adapter 3



        * Enable Network Adapter
        * Attached to: Hostonly Adapter
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


Configuring nodes in Cobbler
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now you need to define nodes in the Cobbler configuration, so that it
knows what OS to install, where to install it, and what configuration
actions to take. On fuel-pm, create a directory for
configuration (wherever you like) and copy the sample config file for
Cobbler from Fuel::



    mkdir cobbler_config
    cd cobbler_config
    cp /etc/puppet/modules/cobbler/examples/cobbler_system.py .
    cp /etc/puppet/modules/cobbler/examples/nodes.yaml .



This configuration file contains definitions for all of the OpenStack
nodes in your cluster. You can either keep them together in one file,
or create a separate file for each node. In any case, lets look at the
configuration for a single node. As you can see, you will need to make
sure that you check and/or edit the following values **for every single
node**:




* The name of the system in Cobbler
* The profile -- switch to ubuntu_1204_x86_64 if necessary
* The correct version of Puppet according to your target OS
* Your domain name
* The hostname and DNS IP
* MAC addresses for every network interface
* The static IP address on management interface eth0
* The default gateway for your network
* The mac address for eth3, **which doesnt exist** in the default  configuration




Heres what the file should look like for fuel-controller-01. Replace
your-domain-name.com and the mac addresses with your own values to
complete the changes::



    fuel-controller-01:
      # for Centos
      profile: "centos63_x86_64"
      # for Ubuntu
      # profile: "ubuntu_1204_x86_64"
      netboot-enabled: "1"
      # for Ubuntu
      # ksmeta: "puppet_version=2.7.19-1puppetlabs2 \
      # for Centos
    ksmeta: "puppet_version=2.7.19-1.el6\
    puppet_auto_setup=1 \
    puppet_master=fuel-pm.your-domain-name.com\
    puppet_enable=0 \
    ntp_enable=1 \
    mco_auto_setup=1 \
    mco_pskey=un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi \
    mco_stomphost=10.0.0.100\
    mco_stompport=61613 \
    mco_stompuser=mcollective \
    mco_stomppassword=AeN5mi5thahz2Aiveexo \
    mco_enable=1"
    # If you need create 'cinder-volumes' VG at install OS -- uncomment this line and move it above in middle of ksmeta section.
    # At this line you need describe list of block devices, that must come in this group.
    # cinder_bd_for_vg=/dev/sdb,/dev/sdc \
      hostname: "fuel-controller-01"
      name-servers: "10.0.0.100"
      name-servers-search: "your-domain-name.com"
      interfaces:
        eth0:
            mac: "52:54:00:0a:39:ec"
            static: "1"
            ip-address: "10.0.0.101"
            netmask: "255.255.255.0"
            dns-name: "fuel-controller-01.your-domain-name.com"
            management: "1"
        eth1:
            mac: "52:54:00:e6:dc:c9"
            static: "0"
        eth2:
            mac: "52:54:00:ae:22:04"
            static: "1"
        eth3:
            mac: "52:54:00:ae:44:42"
        interfaces_extra:
            eth0:
                peerdns: "no"
            eth1:
                peerdns: "no"
            eth2:
                promisc: "yes"
                userctl: "yes"
                peerdns: "no"


Next you need to load these values into Cobbler. For the sake of
convenience, Fuel includes the ./cobbler_system.py script, which reads
the definition of the systems from the yaml file and makes calls to
Cobbler API to insert these systems into the configuration. Run it
using the following command::



    ./cobbler_system.py -f nodes.yaml -l DEBUG



If you've separated the configuration for your nodes into multiple
files, be sure to run this once for each file.


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



**It is important to note** that if you use VLANs in your network
configuration, you always have to keep in mind the fact that PXE
booting does not work on tagged interfaces. Therefore, all your nodes,
including the one where the Cobbler service resides, must share one
untagged VLAN (also called native VLAN). You can use the
dhcp_interface parameter of the cobbler::server class to bind the DHCP
service to a certain interface.



Register the nodes with the Puppet Master
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

At this point you the have OS installed configured on all nodes. Fuel
has also made sure that these nodes have been configured, with Puppet
installed and pointing to the Puppet Master, so the nodes are almost
ready for deploying OpenStack. As the last step, you need to register the
nodes in Puppet master. Do this by running the Puppet agent::



    puppet agent --test



This action generates a certificate, sends it to the Puppet Master for
signing, and then fails. That's fine. It's exactly what we want to
happen; we just want to send the certificate request to the Puppet
Master.



Once you've done this on all four nodes, switch to the Puppet Master
and sign the certificate requests::



    puppet cert list
    puppet cert sign --all



Alternatively, you can sign only a single certificate using::



    puppet cert sign fuel-XX.your-domain-name.com



Now return to the newly installed node and run the Puppet agent again::



    puppet agent --test



This time the process should successfully complete and result in the
"Hello World from fuel-XX" message you defined earlier.



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




    echo "/div/sdv1 /srv/node/sdb1 xfs
    noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
    mount -a

