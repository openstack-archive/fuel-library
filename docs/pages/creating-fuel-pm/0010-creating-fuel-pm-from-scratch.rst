

Installing Puppet Master is a one-time procedure for the entire
infrastructure. Once done, Puppet Master will act as a single point of
control for all of your servers, and you will never have to return to
these installation steps again.


Initial Setup
-------------

On VirtualBox (https://www.virtualbox.org/wiki/Downloads), please create or make sure the following
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


Next, follow these steps to create the virtual hardware:


* Machine -> New



    * Name: fuel-pm
    * Type: Linux
    * Version: Red Hat (64 Bit) or Ubuntu (64 Bit)
    * Memory: 2048MB



* Machine -> Settings -> Network

   * Adapter 1

        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet0

   * Adapter 2
        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: eth0 (or whichever physical network has your internet connection)


It is important that host-only Adapter 1 goes first, as Cobbler will use vboxnet0 for PXE, and VirtualBox boots from the LAN on the first available network adapter.

OS Installation
---------------


    * Pick and download an operating system image. This image will be used as the base OS for the Puppet master node. These insructions assume that you are using CentOS 6.4, but you can also use Ubuntu 12.04.  
	
	  **PLEASE NOTE**: These are the only operating systems on which Fuel 3.0 has been certified. Using other operating systems can, and in many cases will, produce unpredictable results.

        * `CentOS 6.4 <http://isoredirect.centos.org/centos/6/isos/x86_64/>`_: download CentOS-6.4-x86_64-minimal.iso

    * Mount the downloaded ISO to the machine's CD/DVD drive. In case of VirtualBox, mount it to the fuel-pm virtual machine:



        * Machine -> Settings -> Storage -> CD/DVD Drive -> Choose a virtual CD/DVD disk file





    * Boot the server (or VM) from the CD/DVD drive and install the chosen OS.  Be sure to choose the root password carefully.


    * Set up the eth0 interface. This interface will be used for communication between the Puppet Master and Puppet clients, as well as for Cobbler.

      ``vi /etc/sysconfig/network-scripts/ifcfg-eth0``::

        DEVICE="eth0"
        BOOTPROTO="static"
        IPADDR="10.0.0.100"
        NETMASK="255.255.255.0"
        ONBOOT="yes"
        TYPE="Ethernet"
        PEERDNS="no"

      Apply network settings::

        /etc/sysconfig/network-scripts/ifup eth0




    * Set up the eth1 interface. This will be the public interface.


      ``vi /etc/sysconfig/network-scripts/ifcfg-eth1``::

        DEVICE="eth1"
        BOOTPROTO="dhcp"
        ONBOOT="no"
        TYPE="Ethernet"



      Apply network settings::


        /etc/sysconfig/network-scripts/ifup eth1




    * Add DNS for Internet hostnames resolution::

        vi /etc/resolv.conf



      Replace localdomain with your domain name, and replace 8.8.8.8 with your DNS IP. Note: you can look up your DNS server on your host machine using ipconfig /all on Windows, or using cat/etc/resolv.conf under Linux. ::

        search localdomain
        nameserver 8.8.8.8




    * Check that a ping to your host machine works. This means that the management segment is available::

        ping 10.0.0.1




    * Now check to make sure that internet access is working properly::




        ping google.com




    * Next, set up the packages repository:

      ``vi /etc/yum.repos.d/puppet.repo``::

        [puppetlabs-dependencies]
        name=Puppet Labs Dependencies
        baseurl=http://yum.puppetlabs.com/el/$releasever/dependencies/$basearch/
        enabled=1
        gpgcheck=0

        [puppetlabs] 
        name=Puppet Labs Packages
        baseurl=http://yum.puppetlabs.com/el/$releasever/products/$basearch/
        enabled=1 
        gpgcheck=0

    * Install Puppet Master::

        rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
        yum upgrade
        yum install puppet-server-2.7.19
        service puppetmaster start
        chkconfig puppetmaster on
        service iptables stop
        chkconfig iptables off

    * Install PuppetDB::

        yum install puppetdb puppetdb-terminus
        chkconfig puppetdb on



    * Finally, make sure to turn off selinux::




        sed -i s/SELINUX=.*/SELINUX=disabled/ /etc/selinux/config
        setenforce 0



