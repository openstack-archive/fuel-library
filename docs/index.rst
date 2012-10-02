Fuel On Virtualbox (Instructions Draft)
---------------------------------------

Tested on the following setup
=============================

* Mac OS 10.7.4
* Virtualbox 4.1.20
* CentOS-6.3-x86_64-minimal.iso as OS for all VMs

.. note::
    At this point only 64-bit version of CentOS is supported by the library of 
    Puppet manifests Virtual machines

* 1 VM with Puppet master (called “fuel-pm”)
* 4 VMs with Puppet clients
    * 2 for OpenStack controllers (called “fuel-01” and “fuel-02”)
    * 2 for OpenStack compute (called “fuel-03” and “fuel-04”)

Network setup
=============

Every virtual machine has 3 network adapters in Virtualbox:

#. bridged - for internet access, so it can download packages
    * eth0 - every VM gets IP address using DHCP
#. host-only adapter - for communication between Puppet master and Puppet clients
    * eth1 - every VM has a static IP address
    * 10.0.0.1 for host machine
    * 10.0.0.100 for puppet master
    * 10.0.0.101 - 10.0.0.104 for puppet clients
    * 255.255.255.0 network mask
#. host-only adapter - for OpenStack VMs
    * eth2 - without IP address
    * promiscuous mode enabled

Installing Puppet Master (fuel-pm)
==================================

Install CentOS
~~~~~~~~~~~~~~

* CentOS-6.3-x86_64-minimal.iso
* Set up bridge interface (for internet access): 
    * vi /etc/sysconfig/network-scripts/ifcfg-eth0::

        DEVICE="eth0"
        BOOTPROTO="dhcp"
        NM_CONTROLLED="yes"
        ONBOOT="yes"
        TYPE="Ethernet"

    * ifup eth0
* Set up hostonly interface (for puppet communication):
    * vi /etc/sysconfig/network-scripts/ifcfg-eth1
        * set static IP address for puppet master to 10.0.0.100::

            DEVICE="eth1"
            BOOTPROTO="static"
            IPADDR="10.0.0.100"
            NETMASK="255.255.255.0"
            NM_CONTROLLED="yes"
            ONBOOT="yes"
            TYPE="Ethernet"

    * ifup eth1
    * check that ping to host machine works
        * ping 10.0.0.1
* yum upgrade
* vi /etc/yum.repos.d/puppet.repo::
		
    [puppetlabs]
    name=Puppet Labs Packages
    baseurl=http://yum.puppetlabs.com/el/$releasever/products/$basearch/
    enabled=1
    gpgcheck=1
    gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs

* rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm
* yum install puppet-server
* service puppetmaster start
* chkconfig puppetmaster on
* service iptables stop
* chkconfig iptables off
* fix name resolution
    * vi /sbin/dhclient-script 
    .. note::
        (I sincerely apologize, this is very UGLY! find make_resolv_conf() and apply dirty hack, so that /etc/resolv.conf is generated automatically but search is always set to “mirantis.com”)::

            search="mirantis.com"
            if [ -n "${search}" ]; then
                echo "search ${search}" >> $rscf
            fi

    * vi /etc/sysconfig/network
        * HOSTNAME=fuel-pm
    * vi /etc/hosts
        * 10.0.0.100   fuel-pm fuel-pm.mirantis.com
    * hostname fuel-pm
    * reboot
