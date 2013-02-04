
Installing & Configuring Puppet Master
--------------------------------------

If you already have Puppet master installed, you can skip this installation step and go directly to :ref:`puppet-master-stored-config` 

Installing Puppet master is a one-time procedure for the entire infrastructure. Once done, Puppet master will act as a single point of control for all of your servers, and you will never have to return to these installation steps again.

Initial Setup
~~~~~~~~~~~~~

If you plan to provision the Puppet master on hardware, you need to make sure that you can boot your server from an ISO. 

For VirtualBox, follow these steps to create virtual hardware:

* Machine -> New...
    * Name: fuel-pm 
    * Type: Linux
    * Version: Red Hat (64 Bit) or Ubuntu (64 Bit)
* Machine -> Settings... -> Network
    * Adapter 1 
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet0
    * Adapter 2
        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: epn1 (Wi-Fi Airport), or whatever network interface of the host machine with Internet access 
    * It is important that host-only "Adapter 1" goes first, as Cobbler will use vboxnet0 for PXE, and VirtualBox boots from LAN on the first available network adapter.
    * Third adapter is not really needed for Puppet master, as it is only required for OpenStack hosts and communication of tenant VMs.

OS Installation
~~~~~~~~~~~~~~~~~~~

* Pick and download an operating system image. It will be used as a base OS for the Puppet master node:
   * `CentOS 6.3 <http://isoredirect.centos.org/centos/6/isos/x86_64/>`_: download CentOS-6.3-x86_64-minimal.iso
   * `RHEL 6.3 <https://access.redhat.com/home>`_: download rhel-server-6.3-x86_64-boot.iso
   * `Ubuntu 12.04 <https://help.ubuntu.com/community/Installation/MinimalCD>`_: download "Precise Pangolin" Minimal CD

* Mount it to the server CD/DVD drive. In case of VirtualBox, mount it to the fuel-pm virtual machine
    * Machine -> Settings... -> Storage -> CD/DVD Drive -> Choose a virtual CD/DVD disk file...

* Boot server (or VM) from CD/DVD drive and install the chosen OS
    * Choose root password carefully

* Set up eth0 interface. It will be used for communication between Puppet master and Puppet clients, as well as for Cobbler: 
    * CentOS/RHEL
        * ``vi /etc/sysconfig/network-scripts/ifcfg-eth0``::
        
            DEVICE="eth0"
            BOOTPROTO="static"
            IPADDR="10.0.0.100"
            NETMASK="255.255.255.0"
            ONBOOT="yes"
            TYPE="Ethernet"
            PEERDNS="no"

        * Apply network settings::

            /etc/sysconfig/network-scripts/ifup eth0

    * Ubuntu
        * ``vi /etc/network/interfaces`` and add configuration corresponding eth0 interface::

            auto eth0
            iface eth0 inet static
            address 10.0.0.100
            netmask 255.255.255.0
            network 10.0.0.0

        * Apply network settings::

            /etc/init.d/networking restart

    * Add DNS for Internet hostnames resolution. Both CentOS/RHEL and Ubuntu: ``vi /etc/resolv.conf`` (replace "your-domain-name.com" with your domain name, replace "8.8.8.8" with your DNS IP). Note: you can look up your DNS server on your host machine using ``ipconfig /all`` on Windows, or using ``cat /etc/resolv.conf`` under Linux ::

        search your-domain-name.com
        nameserver 8.8.8.8 

    * check that ping to your host machine works. This means that management segment is available::

            ping 10.0.0.1
 
* Set up eth1 interface. It will provide Internet access for Puppet master:
    * CentOS/RHEL
        * ``vi /etc/sysconfig/network-scripts/ifcfg-eth1``::

            DEVICE="eth1"
            BOOTPROTO="dhcp"
            ONBOOT="yes"
            TYPE="Ethernet"

        * Apply network settings::

            /etc/sysconfig/network-scripts/ifup eth1

    * Ubuntu
        * ``vi /etc/network/interfaces`` and add configuration corresponding eth1 interface::

            auto eth1
            iface eth1 inet dhcp

        * Apply network settings::

            /etc/init.d/networking restart

    * Check that Internet access works::

            ping google.com

* Set up the packages repository
    * CentOS/RHEL
        * ``vi /etc/yum.repos.d/puppet.repo``::

            [puppetlabs]
            name=Puppet Labs Packages
            baseurl=http://yum.puppetlabs.com/el/$releasever/products/$basearch/
            enabled=1
            gpgcheck=1
            gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs

    * Ubuntu
        * from command line run::

            wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
            sudo dpkg -i puppetlabs-release-precise.deb

* Install Puppet master
    * CentOS/RHEL::

        rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
        yum upgrade
        yum install puppet-server-2.7.19
        service puppetmaster start
        chkconfig puppetmaster on
        service iptables stop
        chkconfig iptables off

    * Ubuntu::
        
        sudo apt-get update
        apt-get install puppet puppetmaster
        update-rc.d puppetmaster defaults

* Set hostname
    * CentOS/RHEL
        * ``vi /etc/sysconfig/network``::

            HOSTNAME=fuel-pm

    * Ubuntu
        * ``vi /etc/hostname``::

            fuel-pm

    * Both CentOS/RHEL and Ubuntu ``vi /etc/hosts`` (replace "your-domain-name.com" with your domain name)::

            127.0.0.1    localhost fuel-pm
            10.0.0.100   fuel-pm.your-domain-name.com fuel-pm
            10.0.0.101   fuel-controller-01.your-domain-name.com fuel-controller-01
            10.0.0.102   fuel-controller-02.your-domain-name.com fuel-controller-02
            10.0.0.103   fuel-controller-03.your-domain-name.com fuel-controller-03
            10.0.0.110   fuel-compute-01.your-domain-name.com fuel-compute-01

    * Run ``hostname fuel-pm`` or reboot to apply hostname

.. _puppet-master-stored-config:

Enabling Stored Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This section will show how to configure Puppet to use a technique called stored configuration. It is required by Puppet manifests supplied with Fuel, so that they can store exported resources in Puppet database. This makes use of the PuppetDB.

* Install and configure PuppetDB
    * CentOS/RHEL:: 

        yum install puppetdb puppetdb-terminus
        chkconfig puppetdb on		

    * Ubuntu::
        
        apt-get install puppetdb puppetdb-terminus
        update-rc.d puppetdb defaults

* Disable selinux on CentOS/RHEL (otherwise Puppet will not be able to connect to PuppetDB)::
    
    sed -i s/SELINUX=.*/SELINUX=disabled/ /etc/selinux/config
    setenforce 0

* Configure Puppet master to use storeconfigs
    * ``vi /etc/puppet/puppet.conf`` and add following into [master] section::
       
           storeconfigs = true
           storeconfigs_backend = puppetdb

* Configure PuppetDB to use the correct hostname and port
    * ``vi /etc/puppet/puppetdb.conf`` and add following into [main] section (replace "your-domain-name.com" with your domain name; if this file does not exist, it will be created)::

           server = fuel-pm.your-domain-name.com
           port = 8081

* Restart Puppet master to apply settings (Note: these operations may take about two minutes. You can ensure that PuppetDB is running by executing ``telnet fuel-pm.your-domain-name.com 8081``)::
    
    service puppetmaster restart
    puppetdb-ssl-setup
    service puppetmaster restart
    service puppetdb restart


Troubleshooting PuppetDB and SSL
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* If you have a problem with SSL and PuppetDB::

   service puppetdb stop
   rm -rf /etc/puppetdb/ssl
   puppetdb-ssl-setup
   service puppetdb start

   
Testing Puppet
~~~~~~~~~~~~~~

* Put a simple configuration into Puppet (replace "your-domain-name.com" with your domain name), so that when you run puppet from any node, it will display the corresponding "Hello world" message
    * ``vi /etc/puppet/manifests/site.pp``::

        node /fuel-pm.your-domain-name.com/ {
            notify{"Hello world from fuel-pm": }
        }
        node /fuel-controller-01.your-domain-name.com/ {
            notify{"Hello world from fuel-controller-01": }
        }
        node /fuel-controller-02.your-domain-name.com/ {
            notify{"Hello world from fuel-controller-02": }
        }
        node /fuel-controller-03.your-domain-name.com/ {
            notify{"Hello world from fuel-controller-03": }
        }
        node /fuel-compute-01.your-domain-name.com/ {
            notify{"Hello world from fuel-compute-01": }
        }

* If you are planning to install Cobbler on Puppet master node as well, make configuration changes on Puppet master so that it actually knows how to provision software onto itself (replace "your-domain-name.com" with your domain name)
    * ``vi /etc/puppet/puppet.conf``::

        [main]
            # server
            server = fuel-pm.your-domain-name.com

            # enable plugin sync
            pluginsync = true

    * Run puppet agent and observe the "Hello World from fuel-pm" output
        * ``puppet agent --test``

Installing Fuel
~~~~~~~~~~~~~~~

First of all, you should copy a complete Fuel package onto your Puppet master machine. Once you put Fuel there, you should unpack the archive and supply Fuel manifests to Puppet::

    tar -xzf <fuel-archive-name>.tar.gz
    cd <fuel-archive-name>
    cp -Rf deployment/puppet/* /etc/puppet/modules/
    service puppetmaster restart
