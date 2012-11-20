Installation Instructions
=========================

.. contents:: :local:

Introduction
------------

You can follow these instructions in order to get a production-grade OpenStack installation on hardware, or you can just do a dry run using Virtualbox to get of feel of how Fuel works.

If you decide to give Fuel a try using Virtualbox, you will need the latest VirtualBox 4.2.1 as well as a stable host system, preferably Mac OS 10.7.x, CentOS 6.3, or Ubuntu 12.04 (Windows 8 also works, but is definitely not recommended). VirtualBox has to be installed with "extension pack", which enables PXE boot capabilities on Intel network adapters.

The list of certified hardware configuration is coming up in one of the next versions of Fuel.

If you run into any issues during the installation, please check :ref:`common-technical-issues` for common problems and resolutions.

Machines
--------

At the very minimum, you need to have the following machines in your data center:

* 1x Puppet master and Cobbler server (called "fuel-pm", where "pm" stands for puppet master). You can also choose to have Puppet master and Cobbler server on different node
* 3x for OpenStack controllers (called "fuel-01", "fuel-02", and "fuel-03")
* 1x for OpenStack compute (called "fuel-04")

In case of VirtualBox environment, allocate the following resources for these machines:

* 1+ vCPU
* 512+ MB of RAM for controller nodes
* 1024+ MB of RAM for compute nodes
* 8+ GB of HDD (enable dynamic virtual drive expansion in order to save some disk space)

Network Setup
-------------

The current architecture assumes deployment with 3 network adapters, for clarity. However, it can be tuned to support different scenarios, for example deployment with only 2 NICs. So, the adapters will be:  

#. eth0 - public network, with access to the internet
    * we will assume that DHCP is enabled and every machine gets its IP address on this interface automatically through DHCP

#. eth1 - management network. for communication between Puppet master and Puppet clients, as well as PXE/TFTP/DHCP for Cobbler
    * every machine will have a static IP address there
    * you can configure network addresses/network mask according to your needs, but we will be giving instructions using the following network settings on this interface:
        * 10.0.0.100 for puppet master
        * 10.0.0.101-10.0.0.103 for controller nodes
        * 10.0.0.104 for compute nodes
        * 255.255.255.0 network mask
        * if case if VirtualBox environment, host machine will be 10.0.0.1

#. eth2 - for communication between OpenStack VMs
    * without IP address
    * with promiscuous mode enabled

If you are on Virtualbox, create the following host-only adapters:

* Virtualbox -> Preferences...
    * Network -> Add host-only network (vboxnet0)
        * IPv4 address: 10.0.0.1
        * IPv4 mask: 255.255.255.0
        * DHCP server: disabled
    * Network -> Add host-only network (vboxnet1)
        * IPv4 address: 0.0.0.0
        * IPv4 mask: 255.255.255.0
        * DHCP server: disabled
    * If your host operating system is Windows, you need to make an additional step of setting up IP address & network mask under â€œControl Panel -> Network and Internet -> Network and Sharing Centerâ€ for â€œVirtual Host-Only Networkâ€ adapter.

Installing & Configuring Puppet Master
--------------------------------------

If you already have Puppet master installed, you can skip this installation step and go directly to :ref:`puppet-master-stored-config` 

Installing puppet master is a one-time thing for the entire infrastructure. Once done, puppet master will act as a single point of control for all your servers, and you will never have to return to these installation steps again.

Initial Setup
~~~~~~~~~~~~~

If you plan for provision Puppet master on hardware, you need to make sure you can boot your server from an ISO. 

For Virtualbox, follow these steps to create virtual hardware:

* Machine -> New...
    * Name: fuel-pm 
    * Type: Linux
    * Version: Red Hat (64 Bit)
* Machine -> Settings... -> Network
    * Adapter 1
        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: epn1 (Wi-Fi Airport), or whatever network interface of the host machine where you have internet access 
    * Adapter 2
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet0
    * Third adapter is not really needed for Puppet master, as it's only required for OpenStack hosts and communication of tenant VMs.

OS Installation
~~~~~~~~~~~~~~~~~~~

* Pick and download operating system image, it will be used as a base OS for the Puppet master node. We suggest to stick with either of these two:
   * `CentOS-6.3-x86_64-minimal.iso <http://mirror.stanford.edu/yum/pub/centos/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso>`_
   * `rhel-server-6.3-x86_64-boot.iso <https://access.redhat.com/home>`_

Also you can choose the nearest mirror from `CentOS Mirrors List <http://www.centos.org/modules/tinycontent/index.php?id=30>`_

* Mount it to the server CD/DVD drive. In case of Virtualbox, mount it to fuel-pm virtual machine
    * Machine -> Settings... -> Storage -> CD/DVD Drive -> Choose a virtual CD/DVD disk file...

* Boot server (or VM) off CD/DVD drive and install the chosen OS
    * Choose root password carefully

* Set up eth0 interface (it will provide internet access for puppet master): 
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

    * Note: you can look up your DNS server using ``ipconfig /all`` on a host Windows machine, or using ``cat /etc/resolv.conf`` under Linux

    * Check that internet access works
        * ``ping google.com``

    * Set up eth1 interface (for communication between puppet master and puppet clients):
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

    * Install puppet master::

        rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm
        yum upgrade
        yum install puppet-server
        service puppetmaster start
        chkconfig puppetmaster on
        service iptables stop
        chkconfig iptables off

    * Set hostname (replace “mirantis.com” with your domain name)
        * ``vi /etc/sysconfig/network``
            * ``HOSTNAME=fuel-pm``
        * ``vi /etc/hosts``
            * ``10.0.0.100   fuel-pm fuel-pm.mirantis.com``
        * ``hostname fuel-pm``
        * ``reboot``

.. _puppet-master-stored-config:

Enabling Stored Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This section will allow you to configure puppet to use a technique called stored configuration. It's requred by Puppet manifests supplied with Fuel, so that they can store exported resources in Puppet database. This makes use of the Ruby on Rails framework and MySQL.

* Install and configure MySQL & Ruby::

    yum install make
    yum install gcc

    yum install mysql
    yum install mysql-server
    yum install mysql-devel

    yum install rubygems
    yum install ruby-devel

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
        * find the corresponding line and change to ``SELINUX=disabled``
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

* Put a simple configuration into Puppet (replace “mirantis.com” with your domain name), so that when you run puppet from any node, it will display the corresponding "Hello world" message
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

* If you are planning on installing Cobbler on Puppet master node as well, make configuration changes on puppet master so that it actually knows how to provision software onto itself (replace “mirantis.com” with your domain name)
    * ``vi /etc/puppet/puppet.conf``::

        [main]
            # server
            server = fuel-pm.mirantis.com

            # enable plugin sync
            pluginsync = true

    * Run puppet agent and observe "Hello World from fuel-pm" output
        * ``puppet agent --test``

Installing Fuel
~~~~~~~~~~~~~~~

First of all, you must copy a complete Fuel package onto your puppet master machine. Once you put Fuel up these, you should unpack the archive and supply Fuel manifests to Puppet:

    * ``tar -xzf <fuel-archive-name>.tar.gz``
    * ``cd fuel``
    * ``cp -Rf fuel/deployment/puppet/* /etc/puppet/modules/``
    * ``service puppetmaster restart``

Installing & Configuring Cobbler
--------------------------------

Cobbler is bare metal provisioning system which will perform initial installation of Linux on OpenStack nodes. Luckily, we already have a puppet master installed, so we can install Cobbler through Puppet in a matter of seconds rather than doing it manually.

Using Puppet to install Cobbler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On puppet master:

* ``vi /etc/puppet/manifests/site.pp``
* Copy the contents of "fuel/deployment/puppet/cobbler/examples/site.pp" into "/etc/puppet/manifests/site.pp" (replace “mirantis.com” with your domain name):
    .. literalinclude:: ../../deployment/puppet/cobbler/examples/site.pp

* The only thing you might want to change is location of CentOS 6.3 ISO image file (to either a local mirror, or the fastest available internet mirror): ::

    class { cobbler::distro::centos63-x86_64:
        http_iso => "http://mirror.stanford.edu/yum/pub/centos/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso",
        ks_url   => "cobbler",
    }

* The file above assumes you will be installing CentOS 6.3 as a base OS for OpenStack nodes. If you want to install RHEL 6.3, you will need to download its ISO image from `Red Hat Customer Portal <https://access.redhat.com/home>`_, put it on a local HTTP mirror, and add the following lines to the configuration file: ::

    class { cobbler::distro::rhel63-x86_64:
        http_iso => "http://<local-mirror-ip>/iso/rhel-server-6.3-x86_64-boot.iso",
        ks_url => "http://<local-mirror-ip>/rhel/6.3/os/x86_64",
    }

    Class[cobbler::distro::rhel63-x86_64] ->
    Class[cobbler::profile::rhel63-x86_64]

    class { cobbler::profile::rhel63-x86_64: }
  
* Once the configuration is there, Puppet will know that Cobbler must be installed on fuel-pm machine. Once Cobbler is installed, the right distro and profile will be automatically added to it. OS image will be downloaded from the mirror and put into Cobbler as well.
* It is necessary to note that, in a proposed network configuration, the snippet above includes puppet commands to configure forwarding on cobbler node to make external resources available via 10.0.0.0/24 network which is used during installation process (see "enable_nat_all" and "enable_nat_filter")
* run puppet agent to actually install Cobbler on fuel-pm
    * ``puppet agent --test``

Testing cobbler
~~~~~~~~~~~~~~~

* you can check that Cobbler is installed successfully by opening the following URL from your host machine:
    * http://fuel-pm/cobbler_web (u: cobbler, p: cobbler)
* now you have a fully working instance of Cobbler. moreover, it is fully configured and capable of installing the chosen OS (CentOS 6.3, or RHEL 6.3) on target OpenStack nodes


Deploying OpenStack
-------------------

Initial setup
~~~~~~~~~~~~~

If you are using hardware, make sure it is capable of PXE booting over the network from Cobbler.

In case of Virtualnox, create the corresponding virtual machines for your OpenStack nodes in Virtualbox. Do not start them yet.

* Machine -> New...
    * Name: fuel-01 (will need to repeat for fuel-02, fuel-03, and fuel-04)
    * Type: Linux
    * Version: Red Hat (64 Bit)

* Machine -> Settings... -> Network
    * Adapter 1
        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: en1 (Wi-Fi Airport), or whatever network interface of the host machine where you have internet access 

    * Adapter 2
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet0

    * Adapter 3
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet1
        * Advanced -> Promiscuous mode: Allow All

Configuring Cobbler to provision your OpenStack Nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now you need to define nodes in cobbler configuration, so it knows what OS to install where and what configuration actions to take.

On puppet master, create directory with configuration and copy example config file for Cobbler from Fuel repository:

    * ``mkdir cobbler_config``
    * ``cd cobbler_config``
    * ``ln -s ../fuel/deployment/puppet/cobbler/examples/cobbler_system.py .``
    * ``cp ../fuel/deployment/puppet/cobbler/examples/nodes.yaml .``

Edit configuration for bare metal provisioning of nodes (nodes.yaml):

* There is essentially a section for every node, and you have to define all nodes there (fuel-01, fuel-02, fuel-03, and fuel-04). The config for a single node is posted below, while the config for the remaining nodes is very similar
* It's important to get right the following parameters, they are different for every node:
    * name of the system in cobbler, the very first line
    * hostname and DNS name
    * mac addresses for every network interface (you can look them up in Virtualbox, using Machine -> Settings... -> Network -> Adapters)
    * static IP address on management interface eth1
* vi nodes.yaml
    .. literalinclude:: ../../deployment/puppet/cobbler/examples/nodes.yaml

* for the sake of convenience there is "./cobbler_system.py" script, which reads definition of the systems from the yaml file and makes calls to cobbler API to insert these systems into the configuration. run it using the following command:
    * ``./cobbler_system.py -f nodes.yaml -l DEBUG``

Provisioning your OpenStack nodes using Cobbler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now, when cobbler has correct configuration, the only thing you need to do is to PXE-boot your nodes. They will boot over network from DHCP/TFTP provided by cobbler and will be provisioned accordingly, with the right operating system and configuration.

In case of VirtualBox, here is what you have to do for every virtual machine (fuel-01, fuel-02, fuel-03, fuel-04):

* disable bridged network adapter by unchecking  "Machine -> Settings -> Network -> Enable Network Adapter" 
    * the reason for that is --- by default, Virtualbox will attempt to use the first network interface for PXE-boot and it's going to fail. we actually want our machines to PXE-boot from cobbler, which is on 10.0.0.100 (first host-only adapter). so the solution is to temporarily disable "bridged network adapter"
* Machine -> Start
* press F12 during boot and select "l" (LAN) as a bootable media
* once installation is complete
    * log into the machine (l: root, p: r00tme)
    * perform shutdown using "``shutdown -H now``"
* enable back bridged network adapter by checking "Machine -> Settings -> Network -> Enable Network Adapter"
* start the node using Virtualbox
* check that network works correctly
    * ``ping www.google.com``
    * ``ping 10.0.0.100``

It is important to note that if you use VLANs in your network configuration you always have to keep in mind the fact that PXE booting does not work on tagged interfaces. Therefore, all your nodes including the one where cobbler service lives, must share one untagged VLAN (also called "native VLAN"). You can use dhcp_interface parameter of cobbler::server class to bind dhcp service to certain interface.

Now, you have OS installed and configured on all nodes. Moreover, puppet is installed on the nodes as well and its configuration points to our puppet master. Therefore the nodes are almost ready for deploying OpenStack. Now, as the last step, you need to register nodes in puppet master:

* ``puppet agent --test``
    * it will generate a certificate, send to puppet master for signing, and then fail
* switch to puppet master and execute:
    * ``puppet cert list``
    * ``puppet cert sign --all``
        * alternatively, you can sign only a single certificate using "puppet cert sign fuel-XX.mirantis.com"
* ``puppet agent --test``
    * it should successfully complete and result in "Hello World from fuel-XX" message

Installing OpenStack
~~~~~~~~~~~~~~~~~~~~

In case of VirtualBox, it's recommended to save current state of every virtual machine using the mechanism of snapshot. It is helpful to have a point to revert to, so you can install OpenStack using puppet, then revert and try one more time if needed.

* On puppet master
    * create file with definition of networks, nodes, and roles. assume you are deploying a compact configuration, with Controllers and Swift combined:
        * ``cp fuel/deployment/puppet/openstack/examples/site_openstack_swift_compact.pp /etc/puppet/manifests/site.pp``
    * ``vi /etc/puppet/manifests/site.pp``
        .. literalinclude:: ../../deployment/puppet/openstack/examples/site_openstack_swift_compact.pp
    * create directory with keys, give it the appropriate permissions, and generate keys themselves 
        * ``mkdir /var/lib/puppet/ssh_keys``
        * ``cd /var/lib/puppet/ssh_keys``
        * ``ssh-keygen -f openstack``
        * ``chown -R puppet:puppet /var/lib/puppet/ssh_keys/``
    * edit the file ``/etc/puppet/fileserver.conf`` and append the following lines: ::

        [ssh_keys]
        path /var/lib/puppet/ssh_keys
        allow *

* Install OpenStack controller nodes sequentially, one by one
    * run "``puppet agent --test``" on fuel-01
    * wait for installation to complete
    * repeat the same for fuel-02 and fuel-03
    * .. important:: it's important to establish the cluster of OpenStack controllers in sequential fashion, due to the nature of assembling MySQL cluster based on Galera

* Install OpenStack compute nodes, you can do it in parallel if you want
    * run "``puppet agent --test``" on fuel-04
    * wait for installation to complete

* You OpenStack cluster is ready to go

.. _common-technical-issues:

Common Technical Issues
-----------------------

#. Puppet fails with "err: Could not retrieve catalog from remote server: Error 400 on SERVER: undefined method 'fact_merge' for nil:NilClass"
    * bug: http://projects.puppetlabs.com/issues/3234
    * workaround: "service puppetmaster restart"
#. Puppet client will never resend certificate to puppet master. Certificate cannot be signed and verified.
    * bug: http://projects.puppetlabs.com/issues/4680
    * workaround:
        * on puppet client: "``rm -f /etc/puppet/ssl/certificate_requests/\*.pem``", and "``rm -f /etc/puppet/ssl/certs/\*.pem``"
        * on puppet master: "``rm -f /var/lib/puppet/ssl/ca/requests/\*.pem``"

#. My manifests are up to date under /etc/puppet/manifests, but puppet master keeps serving previous version of manifests to the clients. Manifests seem to be cached by puppet master.
    * issue: https://groups.google.com/forum/?fromgroups=#!topic/puppet-users/OpCBjV1nR2M
    * workaround: "``service puppetmaster restart``"
#. You may get timeout error for fuel-0x when running "``puppet-agent --test``" to install openstack when using HDD instead of SSD
    * | Sep 26 17:56:15 fuel-02 puppet-agent[1493]: Could not retrieve catalog from remote server: execution expired
      | Sep 26 17:56:15 fuel-02 puppet-agent[1493]: Not using cache on failed catalog
      | Sep 26 17:56:15 fuel-02 puppet-agent[1493]: Could not retrieve catalog; skipping run

    * workaround: ``vi /etc/puppet/puppet.conf``
        * add: ``configtimeout = 1200``
#. while running "``puppet agent --test``" error messages below can occurs:
    * | err: /File[/var/lib/puppet/lib]: Could not evaluate: Could not retrieve information from environment production source(s) puppet://fuel-pm.mirantis.com/plugins

    and
      | err: Could not retrieve catalog from remote server: Error 400 on SERVER: stack level too deep
      | warning: Not using cache on failed catalog
      | err: Could not retrieve catalog; skipping run

    * The first problem can be solved using the way discribed here http://projects.reductivelabs.com/issues/2244
    * The second problem can be solved by rebooting puppet-master

