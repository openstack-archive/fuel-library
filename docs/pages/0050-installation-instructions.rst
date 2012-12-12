Installation Instructions
=========================

.. contents:: :local:

Introduction
------------

You can follow these instructions in order to get a production-grade OpenStack installation on hardware, or you can just do a dry run using VirtualBox to get a feel of how Fuel works.

If you decide to give Fuel a try using VirtualBox, you will need the latest VirtualBox 4.2.1 as well as a stable host system, preferably Mac OS 10.7.x, CentOS 6.3, or Ubuntu 12.04. Windows 8 also works, but is definitely not recommended. VirtualBox has to be installed with "extension pack", which enables PXE boot capabilities on Intel network adapters.

The list of certified hardware configuration is coming up in one of the next versions of Fuel.

If you run into any issues during the installation, please check :ref:`common-technical-issues` for a list of common problems and their resolutions.

Machines
--------

At the very minimum, you need to have the following machines in your data center:

* 1x Puppet master and Cobbler server (called "fuel-pm", where "pm" stands for puppet master). You can also choose to have Puppet master and Cobbler server on different nodes
* 3x for OpenStack controllers (called "fuel-01", "fuel-02", and "fuel-03")
* 1x for OpenStack compute (called "fuel-04")

In case of VirtualBox environment, allocate the following resources for these machines:

* 1+ vCPU
* 512+ MB of RAM for controller nodes
* 1024+ MB of RAM for compute nodes
* 8+ GB of HDD (enable dynamic virtual drive expansion in order to save some disk space)

Network Setup
-------------

The current architecture assumes deployment with 3 network adapters, for clarity. However, it can be tuned to support different scenarios, for example, deployment with only 2 NICs. Hence, the adapters will be:  

#. eth0 - public network, with access to Internet
    * we will assume that DHCP is enabled and every machine gets its IP address on this interface automatically through DHCP

#. eth1 - management network, for communication between Puppet master and Puppet clients, as well as PXE/TFTP/DHCP for Cobbler
    * every machine will have a static IP address there
    * you can configure network addresses/network mask according to your needs, but we will give instructions using the following network settings on this interface:
        * 10.0.0.100 for puppet master
        * 10.0.0.101-10.0.0.103 for controller nodes
        * 10.0.0.104 for compute nodes
        * 255.255.255.0 network mask
        * in the case of VirtualBox environment, host machine will be 10.0.0.1

#. eth2 - for communication between OpenStack VMs
    * without IP address
    * with promiscuous mode enabled

If you are on VirtualBox, create the following host-only adapters:

* Virtualbox -> Preferences...
    * Network -> Add host-only network (vboxnet0)
        * IPv4 address: 10.0.0.1
        * IPv4 mask: 255.255.255.0
        * DHCP server: disabled
    * Network -> Add host-only network (vboxnet1)
        * IPv4 address: 0.0.0.0
        * IPv4 mask: 255.255.255.0
        * DHCP server: disabled
    * If your host operating system is Windows, you need to make an additional step of setting up IP address & network mask under "Control Panel -> Network and Internet -> Network and Sharing Center" for the "Virtual Host-Only Network" adapter.

Installing & Configuring Puppet Master
--------------------------------------

If you already have Puppet master installed, you can skip this installation step and go directly to :ref:`puppet-master-stored-config` 

Installing Puppet master is a one-time procedure for the entire infrastructure. Once done, Puppet master will act as a single point of control for all of your servers, and you will never have to return to these installation steps again.

Initial Setup
~~~~~~~~~~~~~

If you plan to provision Puppet master on hardware, you need to make sure you can boot your server from an ISO. 

For VirtualBox, follow these steps to create virtual hardware:

* Machine -> New...
    * Name: fuel-pm 
    * Type: Linux
    * Version: Red Hat (64 Bit)
* Machine -> Settings... -> Network
    * Adapter 1
        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: epn1 (Wi-Fi Airport), or whatever network interface of the host machine where you have Internet access 
    * Adapter 2
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet0
    * Third adapter is not really needed for Puppet master, as it is only required for OpenStack hosts and communication of tenant VMs.

OS Installation
~~~~~~~~~~~~~~~~~~~

* Pick and download operating system image. It will be used as a base OS for the Puppet master node. We suggest that you stick to either of the following two options:
   * `CentOS-6.3-x86_64-minimal.iso <http://mirror.stanford.edu/yum/pub/centos/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso>`_
   * `rhel-server-6.3-x86_64-boot.iso <https://access.redhat.com/home>`_

* Mount it to the server CD/DVD drive. In case of VirtualBox, mount it to the fuel-pm virtual machine
    * Machine -> Settings... -> Storage -> CD/DVD Drive -> Choose a virtual CD/DVD disk file...

* Boot server (or VM) from CD/DVD drive and install the OS chosen 
    * Choose root password carefully

* Set up eth0 interface (it will provide Internet access for Puppet master): 
    * ``vi /etc/sysconfig/network-scripts/ifcfg-eth0``::

        DEVICE="eth0"
        BOOTPROTO="dhcp"
        ONBOOT="yes"
        TYPE="Ethernet"
        PEERDNS="no"

    * ``ifup eth0``
    * ``vi /etc/resolv.conf`` (replace "mirantis.com" with your domain name, replace "8.8.8.8" with your DNS IP)::

        search mirantis.com
        nameserver 8.8.8.8 

    * Note: You can look up your DNS server using ``ipconfig /all`` on a host Windows machine, or using ``cat /etc/resolv.conf`` under Linux

    * Check that Internet access works
        * ``ping google.com``

    * Set up eth1 interface (for communication between Puppet master and Puppet clients):
        * ``vi /etc/sysconfig/network-scripts/ifcfg-eth1``::

            DEVICE="eth1"
            BOOTPROTO="static"
            IPADDR="10.0.0.100"
            NETMASK="255.255.255.0"
            ONBOOT="yes"
            TYPE="Ethernet"
            PEERDNS="no"

        * ``ifup eth1``
        * check that ping to your host machine works
            * ``ping 10.0.0.1``

    * ``vi /etc/yum.repos.d/puppet.repo``::

        [puppetlabs]
        name=Puppet Labs Packages
        baseurl=http://yum.puppetlabs.com/el/$releasever/products/$basearch/
        enabled=1
        gpgcheck=1
        gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs

    * Install Puppet master::

        rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm
        yum upgrade
        yum install puppet-server
        service puppetmaster start
        chkconfig puppetmaster on
        service iptables stop
        chkconfig iptables off

    * Set hostname:
        * ``vi /etc/sysconfig/network``
            * ``HOSTNAME=fuel-pm``
        * ``vi /etc/hosts``
            * ``10.0.0.100   fuel-pm fuel-pm.mirantis.com``
        * ``hostname fuel-pm``
        * ``reboot``

.. _puppet-master-stored-config:

Enabling Stored Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This section will allow you to configure Puppet to use a technique called stored configuration. It is requred by Puppet manifests supplied with Fuel, so that they can store exported resources in Puppet database. This makes use of the Ruby on Rails framework and MySQL.

* Install and configure MySQL & Ruby::

    yum install mysql
    yum install mysql-server
    yum install mysql-devel
    yum install rubygems
    yum install ruby-devel
    yum install make
    yum install gcc
    gem install rails
    gem install mysql
    chkconfig mysqld on
    service mysqld start
    mysql -u root
        create database puppet;
        grant all privileges on puppet.* to puppet@localhost identified by 'password';

* Apply workaround for http://projects.puppetlabs.com/issues/9290::

    gem uninstall activerecord
    gem install activerecord -v 3.0.10

* Disable selinux (otherwise Puppet will not be able to connect to MySQL)
    * ``vi /etc/selinux/config``
        * find the corresponding line and change it to ``SELINUX=disabled``
    * ``setenforce 0``

* Configure Puppet master to use storeconfigs. 
    * ``vi /etc/puppet/puppet.conf``::

        [master]
            storeconfigs = true
            dbadapter = mysql
            dbuser = puppet
            dbpassword = password
            dbserver = localhost
            dbsocket = /var/lib/mysql/mysql.sock
            rundir = /var/run/puppet

    * ``service puppetmaster restart``
                        
Testing Puppet
~~~~~~~~~~~~~~

* Put a simple configuration into Puppet, so that when you run Puppet from any node, it will display the corresponding "Hello, World" message
    * ``vi /etc/puppet/manifests/site.pp``::

        node /fuel-pm.mirantis.com/ {
            notify{"Hello world from fuel-pm": }
        }
        node /fuel-01.mirantis.com/ {
            notify{"Hello world from fuel-01": }
        }
        node /fuel-02.mirantis.com/ {
            notify{"Hello world from fuel-02": }
        }
        node /fuel-03.mirantis.com/ {
            notify{"Hello world from fuel-03": }
        }
        node /fuel-04.mirantis.com/ {
            notify{"Hello world from fuel-04": }
        }

* If you are planning to install Cobbler on Puppet master node as well, make configuration changes on Puppet master so that it actually knows how to provision software onto itself
    * ``vi /etc/puppet/puppet.conf``::

        [main]
            # server
            server = fuel-pm.mirantis.com

            # enable plugin sync
            pluginsync = true

    * Run Puppet agent and observe the "Hello World from fuel-pm" output
        * ``puppet agent --test``

Installing Fuel
~~~~~~~~~~~~~~~

First of all, you should copy a complete Fuel package onto your Puppet master machine. Once you upload Fuel, you should unpack the archive and supply Fuel manifests to Puppet:

    * ``tar -xzf <fuel-archive-name>.tar.gz``
    * ``cd fuel``
    * ``cp -Rf fuel/deployment/puppet/* /etc/puppet/modules/``
    * ``service puppetmaster restart``

Installing & Configuring Cobbler
--------------------------------

Cobbler is bare metal provisioning system which will perform initial installation of Linux on OpenStack nodes. Luckily, we already have a Puppet master installed, so we can install Cobbler through Puppet in a matter of seconds rather than do it manually.

Using Puppet to install Cobbler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On Puppet master:

* ``vi /etc/puppet/manifests/site.pp``
* Copy the content of "fuel/deployment/puppet/cobbler/examples/site.pp" into "/etc/puppet/manifests/site.pp":
    .. literalinclude:: ../../deployment/puppet/cobbler/examples/site.pp

* The only thing you might want to change is the location of CentOS 6.3 ISO image file (to either a local mirror, or the fastest available Internet mirror): ::

    class { cobbler::distro::centos63-x86_64:
        http_iso => "http://mirror.facebook.net/centos/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso",
        ks_url   => "cobbler",
    }

* The file above assumes that you will install CentOS 6.3 as a base OS for OpenStack nodes. If you want to install RHEL 6.3, you will need to download its ISO image from `Red Hat Customer Portal <https://access.redhat.com/home>`_, put it on a local HTTP mirror, and add the following lines to the configuration file: ::

    class { cobbler::distro::rhel63-x86_64:
        http_iso => "http://<local-mirror-ip>/iso/rhel-server-6.3-x86_64-boot.iso",
        ks_url => "http://<local-mirror-ip>/rhel/6.3/os/x86_64",
    }

    Class[cobbler::distro::rhel63-x86_64] ->
    Class[cobbler::profile::rhel63-x86_64]

    class { cobbler::profile::rhel63-x86_64: }
  
* Once the configuration is there, Puppet will know that Cobbler is to be installed on fuel-pm machine. Once Cobbler is installed, the right distro and profile will be automatically added to it. OS image will be downloaded from the mirror and put into Cobbler as well.
* It is necessary to note: in the proposed network configuration, the snippet above includes Puppet commands to configure forwarding on Cobbler node to make external resources available via the 10.0.0.0/24 network which is used during the installation process (see "enable_nat_all" and "enable_nat_filter")
* run Puppet agent to actually install Cobbler on fuel-pm
    * ``puppet agent --test``

Testing Cobbler
~~~~~~~~~~~~~~~

* You can check that Cobbler is installed successfully by opening the following URL from your host machine:
    * http://fuel-pm/cobbler_web (u: cobbler, p: cobbler)
* Now you have a fully working instance of Cobbler. Moreover, it is fully configured and capable of installing the chosen OS (CentOS 6.3, or RHEL 6.3) on the target OpenStack nodes


Deploying OpenStack
-------------------

Initial setup
~~~~~~~~~~~~~

If you are using hardware, make sure it is capable of PXE booting over the network from Cobbler.

In case of VirtualBox, create the corresponding virtual machines for your OpenStack nodes in VirtualBox. Do not start them yet.

* Machine -> New...
    * Name: fuel-01 (will need to repeat for fuel-02, fuel-03, and fuel-04)
    * Type: Linux
    * Version: Red Hat (64 Bit)

* Machine -> Settings... -> Network
    * Adapter 1
        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: en1 (Wi-Fi Airport), or whatever network interface of the host machine where you have Internet access 

    * Adapter 2
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet0

    * Adapter 3
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet1
        * Advanced -> Promiscuous mode: Allow All

Configuring Cobbler to provision your OpenStack nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now you need to define nodes in the Cobbler configuration, so that it knows what OS to install, where to install it, and what configuration actions to take.

On Puppet master, create a directory with configuration and copy the sample config file for Cobbler from Fuel repository:

    * ``mkdir cobbler_config``
    * ``cd cobbler_config``
    * ``ln -s ../fuel/deployment/puppet/cobbler/examples/cobbler_system.py .``
    * ``cp ../fuel/deployment/puppet/cobbler/examples/nodes.yaml .``

Edit configuration for bare metal provisioning of nodes (nodes.yaml):

* There is essentially a section for every node, and you have to define all nodes there (fuel-01, fuel-02, fuel-03, and fuel-04). The config for a single node is given below, while the config for the remaining nodes is very similar
* It is important to get the following parameters correctly specified (they are different for every node):
    * Name of the system in Cobbler, the very first line
    * Hostname and DNS name
    * MAC addresses for every network interface (you can look them up in VirtualBox, using Machine -> Settings... -> Network -> Adapters)
    * Static IP address on management interface eth1
* vi nodes.yaml
    .. literalinclude:: ../../deployment/puppet/cobbler/examples/nodes.yaml

* For the sake of convenience the "./cobbler_system.py" script is provided: it reads the definition of the systems from the yaml file and makes calls to Cobbler API to insert these systems into the configuration. Run it using the following command:
    * ``./cobbler_system.py -f nodes.yaml -l DEBUG``

Provisioning your OpenStack nodes using Cobbler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now, when Cobbler has correct configuration, the only thing you need to do is to PXE-boot your nodes. They will boot over a network from DHCP/TFTP provided by cobbler and will be provisioned accordingly, with the specified operating system and configuration.

In case of VirtualBox, here is what you have to do for every virtual machine (fuel-01, fuel-02, fuel-03, fuel-04):

* disable bridged network adapter by unchecking  "Machine -> Settings -> Network -> Enable Network Adapter" 
    * Reason for that: by default, VirtualBox will attempt to use the first network interface for PXE-boot and it is going to fail. We actually want our machines to PXE-boot from Cobbler which is on 10.0.0.100 (first host-only adapter). So the solution is to temporarily disable "bridged network adapter".
* Machine -> Start
* press F12 during boot and select "l" (LAN) as a bootable media
* once installation is complete:
    * log into the machine (l: root, p: r00tme)
    * perform shutdown using "``shutdown -H now``"
* enable back the bridged network adapter by checking "Machine -> Settings -> Network -> Enable Network Adapter"
* start the node using VirtualBox
* check that the network works correctly
    * ``ping www.google.com``
    * ``ping 10.0.0.100``

It is important to note that if you use VLANs in your network configuration, you always have to keep in mind the fact that PXE booting does not work on tagged interfaces. Therefore, all your nodes including the one where the Cobbler service resides must share one untagged VLAN (also called "native VLAN"). You can use ``dhcp_interface`` parameter of the ``cobbler::server`` class to bind a DHCP service to a certain interface.

Now you have OS installed and configured on all nodes. Moreover, Puppet is installed on the nodes as well and its configuration points to our Puppet master. Therefore, the nodes are almost ready for deploying OpenStack. Now, as the last step, you need to register nodes in Puppet master:

* ``puppet agent --test``
    * it will generate a certificate, send it to Puppet master for signing, and then fail
* switch to Puppet master and execute:
    * ``puppet cert list``
    * ``puppet cert sign --all``
        * alternatively, you can sign only a single certificate using "puppet cert sign fuel-XX.mirantis.com"
* ``puppet agent --test``
    * it should successfully complete and result in the "Hello world from fuel-XX" message

Installing OpenStack
~~~~~~~~~~~~~~~~~~~~

In case of VirtualBox, it is recommended to save the current state of every virtual machine using the mechanism of snapshots. It is helpful to have a point to revert to, so that you could install OpenStack using Puppet and then revert and try one more time, if necessary.

* In Puppet master
    * Create a file with the definition of networks, nodes, and roles. Assume you are deploying a compact configuration, with Controllers and Swift combined:
        * ``cp fuel/deployment/puppet/openstack/examples/site_openstack_swift_compact.pp /etc/puppet/manifests/site.pp``
    * ``vi /etc/puppet/manifests/site.pp``
        .. literalinclude:: ../../deployment/puppet/openstack/examples/site_openstack_swift_compact.pp
    * Create directory ``/var/lib/puppet/ssh_keys`` and do ``ssh-keygen -f openstack`` there
    * Edit file ``/etc/puppet/fileserver.conf`` and append the following lines there: ::

        [ssh_keys]
        path /var/lib/puppet/ssh_keys
        allow *

* Install OpenStack controller nodes sequentially, one by one
    * run "``puppet agent --test``" on fuel-01
    * wait for the installation to complete
    * repeat the same for fuel-02 and fuel-03
    * .. Important:: It is important to establish the cluster of OpenStack controllers in sequential fashion, due to the nature of assembling MySQL cluster based on Galera

* Install OpenStack compute nodes, you can do it in parallel if you want
    * run "``puppet agent --test``" on fuel-04
    * wait for the installation to complete

* Your OpenStack cluster is ready to go

.. _common-technical-issues:

Common Technical Issues
-----------------------

#. Puppet fails with "err: Could not retrieve catalog from remote server: Error 400 on SERVER: undefined method 'fact_merge' for nil:NilClass"
    * bug: http://projects.puppetlabs.com/issues/3234
    * workaround: "service puppetmaster restart"
#. Puppet client will never resend certificate to Puppet master. Certificate cannot be signed and verified.
    * bug: http://projects.puppetlabs.com/issues/4680
    * workaround:
        * on Puppet client: "``rm -f /etc/puppet/ssl/certificate_requests/\*.pem``", and "``rm -f /etc/puppet/ssl/certs/\*.pem``"
        * on Puppet master: "``rm -f /var/lib/puppet/ssl/ca/requests/\*.pem``"

#. The manifests are up-to-date under ``/etc/puppet/manifests``, but Puppet master keeps serving the previous version of manifests to the clients. The manifests seem to be cached by Puppet master.
    * issue: https://groups.google.com/forum/?fromgroups=#!topic/puppet-users/OpCBjV1nR2M
    * workaround: "``service puppetmaster restart``"
#. Timeout error for fuel-0x on running "``puppet-agent --test``" to install OpenStack when using HDD instead of SSD
    * | Sep 26 17:56:15 fuel-02 puppet-agent[1493]: Could not retrieve catalog from remote server: execution expired
      | Sep 26 17:56:15 fuel-02 puppet-agent[1493]: Not using cache on failed catalog
      | Sep 26 17:56:15 fuel-02 puppet-agent[1493]: Could not retrieve catalog; skipping run

    * workaround: ``vi /etc/puppet/puppet.conf``
        * add: ``configtimeout = 1200``
#. While running "``puppet agent --test``", the error messages below occur:
    * | err: /File[/var/lib/puppet/lib]: Could not evaluate: Could not retrieve information from environment production source(s) puppet://fuel-pm.mirantis.com/plugins

    and
      | err: Could not retrieve catalog from remote server: Error 400 on SERVER: stack level too deep
      | warning: Not using cache on failed catalog
      | err: Could not retrieve catalog; skipping run

    * The first problem can be solved using the way described here: http://projects.reductivelabs.com/issues/2244
    * The second problem can be solved by rebooting Puppet master

