
Installing & Configuring Puppet Master
--------------------------------------

If you already have Puppet master installed, you can skip this installation step and go directly to :ref:`puppet-master-stored-config` 

Installing Puppet master is a one-time procedure for the entire infrastructure. Once done, Puppet master will act as a single point of control for all of your servers, and you will never have to return to these installation steps again.

Initial Setup
~~~~~~~~~~~~~

If you plan to provision the Puppet master on hardware, you need to make sure you can boot your server from an ISO. 

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
~~~~~~~~~~~~~~~

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

        rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
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

This section will show how to configure Puppet to use a technique called stored configuration. It is requred by Puppet manifests supplied with Fuel, so that they can store exported resources in Puppet database. This makes use of the Ruby on Rails framework and MySQL.

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
        node /fuel-.+-[\d+].mirantis.com/ {
            notify{"Hello world": }
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

