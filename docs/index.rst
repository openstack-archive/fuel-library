Fuel On Virtualbox (Instructions Draft)
---------------------------------------

Table of contents
=================

.. toctree::
   :maxdepth: 2

OS/Software setup
=================

* Mac OS 10.7.4
* Virtualbox 4.2.1 with extension pack to enable PXE booting
* CentOS-6.3-x86_64-minimal.iso as OS for all VMs
    .. note:: Only 64-bit version of CentOS is supported

Virtual machines
================

* 1 VM with Puppet master and Cobbler server (called "fuel-pm", where "pm" stands for puppet master)
* 3 VMs with Puppet client
    * 2 for OpenStack controllers (called "fuel-01" and "fuel-02")
    * 1 for OpenStack compute (called "fuel-03")
* all machines have 1 vCPU, 512 MB of RAM , and 8GB of HDD with dynamic virtual drive expansion

Network setup
=============

Every virtual machine will have 3 network adapters in Virtualbox:
#. bridged - for internet access, so it can download packages
    * eth0 - every VM gets IP address through DHCP
#. host-only adapter - for communication between Puppet master and Puppet clients, as well as PXE/DHCP for Cobbler
    * eth1 - every VM has a static IP address
    * IP addresses/network masks will be as follows
        * 10.0.0.1 for your host machine
        * 10.0.0.100 for puppet master
        * 10.0.0.101-10.0.0.104 for puppet clients
        * 255.255.255.0 network mask
#. host-only adapter - for OpenStack VMs
    * eth2 - without IP address
    * promiscuous mode enabled

So, before you start creating virtual machines, you should create the following host-only adapters in Virtualbox:
* Virtualbox -> Preferences...
    * Network -> Add host-only network (vboxnet0)
        * IPv4 address: 10.0.0.1
        * IPv4 mask: 255.255.255.0
        * DHCP server: disabled
    * Network -> Add host-only network (vboxnet1)
        * IPv4 address: 0.0.0.0
        * IPv4 mask: 255.255.255.0
        * DHCP server: disabled

Installing & configuring puppet master (fuel-pm)
================================================

Installing puppet master is a one-time thing for the entire infrastructure. ItÎéÎ÷s a lengthy process, but you will never have to return to it again once you are complete these steps.

VM Creation
~~~~~~~~~~~

* Machine -> New...
    * Name: fuel-pmvi 
    * Type: Linux
    * Version: Red Hat (64 Bit)
* Machine -> Settings... -> Network
    * Adapter 1
        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: epn1 (Wi-Fi Airport), or whatever interface where you have internet access 
    * Adapter 2
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet0
    * Third adapter is not really needed for Puppet master, as itÎéÎ÷s only required for OpenStack hosts and communication of tenant VMs.

CentOS Installation
~~~~~~~~~~~~~~~~~~~

* Download `CentOS-6.3-x86_64-minimal.iso <http://mirror.stanford.edu/yum/pub/centos/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso>`_

* Mount it to the fuel-pm virtual machine
    * Machine -> Settings... -> Storage -> CD/DVD Drive -> Choose a virtual CD/DVD disk file...

* Run virtual machine and install CentOS
    * Choose root password carefully

* Set up eth0 interface (it will provide internet access for puppet master): 
    * ``vi /etc/sysconfig/network-scripts/ifcfg-eth0``::

        DEVICE="eth0"
        BOOTPROTO="dhcp"
        ONBOOT="yes"
        TYPE="Ethernet"
        PEERDNS="no"

    * ``ifup eth0``
    * ``vi /etc/resolv.conf``::

        search mirantis.com
        nameserver <IP-ADDRESS-OF-YOUR-DNS-SERVER>

    * check that internet access works
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

    * Set hostname
        * ``vi /etc/sysconfig/network``
            * ``HOSTNAME=fuel-pm``
        * ``vi /etc/hosts``
            * ``10.0.0.100   fuel-pm fuel-pm.mirantis.com``
        * ``hostname fuel-pm``
        * reboot

Enabling stored configuration on puppet master
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This paragraph will enable puppet to use a technique called stored configuration, to store exported resources in a database. This makes use of the Ruby on Rails framework and MySQL.

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

    * ``service puppetmaster restart``
                        
Puppet Testing
~~~~~~~~~~~~~~

* Put a simple configuration into Puppet, so that when you run puppet from any node, it will display the corresponding "Hello world" message
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

* Make configuration changes, so that puppet master can actually act as a puppet client and provision software onto itself (it is useful, as we will be installing Cobbler on the same node as Puppet master)
    * ``vi /etc/puppet/puppet.conf``::

        [main]
            # server
            server = fuel-pm.mirantis.com

            # enable plugin sync
            pluginsync = true

* Run puppet agent and observe "Hello World from fuel-pm" output
    * ``puppet agent --test``

Installing Fuel onto puppet master
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You must load a complete copy of Fuel onto puppet master machine. The preferred way is to run git clone & git pull directly from the puppet master, so you can get the latest changes from the repository quickly and whenever you want. So, do the following:host

* ``yum install git``
* make sure ".ssh" directory is there on puppet master
    * ``mkdir /root/.ssh``
* upload your private key to puppet master, e.g. you can run the following from your host machine
    * ``scp ~/.ssh/id_rsa root@fuel-pm:/root/.ssh/``
* on puppet master, create script for automated update of puppet manifests. On the first run it will do a complete clone of Fuel git repository. On subsequent runs, it will pull incremental changes using "./pull-all.sh" script which is contained in the Fuel repository. 
    * ``vi updateRecipes.sh``::

        #!/bin/bash

        if [ -d "fuel" ]; then
            cd fuel
            ./pull-all.sh
            cd ..
        else
            git clone --recursive gitolite@gitolite.mirantis.com:fuel/fuel.git
            cd fuel
            git submodule foreach git checkout master
            cd ..
        fi

        rm -rf /etc/puppet/modules/*
        cp -Rf fuel/deployment/puppet/* /etc/puppet/modules/
        service puppetmaster restart

    * ``chmod a+x ./updateRecipes.sh``
    * run the script and wait until it gets a complete Fuel code
        * ``./updateRecipes.sh``

Installing & configuring cobbler (fuel-pm)
==========================================

Cobbler is bare metal provisioning system which will perform initial installation of Linux on OpenStack nodes. Luckily, we already have a puppet master installed, so let\'s install Cobbler through Puppet rather than doing it manually.

Using puppet to install Cobbler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On puppet master:

* ``vi /etc/puppet/manifests/site.pp``
* copy the contents of "fuel/deployment/puppet/cobbler/examples/site.pp” into “/etc/puppet/manifests/site.pp”:::

    node /fuel-pm/ {

        Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

        exec { "enable_forwarding":
            command => "echo 1 > /proc/sys/net/ipv4/ip_forward",
        }

        exec { "enable_nat_all":
            command => "iptables -t nat -I POSTROUTING 1 -s 10.0.0.0/24 ! -d 10.0.0.0/24 -j MASQUERADE",
            unless => "iptables -t nat -S POSTROUTING | grep -q \"^-A POSTROUTING -s 10.0.0.0/24 ! -d 10.0.0.0/24 -j MASQUERADE\""
        }

        exec { "enable_nat_filter":
            command => "iptables -t filter -I FORWARD 1 -j ACCEPT",
            unless => "iptables -t filter -S FORWARD | grep -q \"^-A FORWARD 1 -j ACCEPT\""
        }

        class { cobbler::server:
            server              => '10.0.0.100',

            domain_name         => 'mirantis.com',
            name_server         => '10.0.0.100',
            next_server         => '10.0.0.100',

            dhcp_start_address  => '10.0.0.201',
            dhcp_end_address    => '10.0.0.254',
            dhcp_netmask        => '255.255.255.0',
            dhcp_gateway        => '10.0.0.100',
            dhcp_interface      => 'eth1',

            cobbler_user        => 'cobbler',
            cobbler_password    => 'cobbler',

            pxetimeout          => '0'
        }

        Class[cobbler::server] ->
        Class[cobbler::distro::centos63-x86_64]

        class { cobbler::distro::centos63-x86_64:
            http_iso => "http://mirror.facebook.net/centos/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso",
            ks_url   => "cobbler",
        }


        Class[cobbler::distro::centos63-x86_64] ->
        Class[cobbler::profile::centos63-x86_64]

        class { cobbler::profile::centos63-x86_64: }

        package {"python-argparse": }
    }

* if you are precisely following this guide and your network configuration is identical, you can keep the entire file as is
* the only thing you might want to change is location of CentOS 6.3 ISO image file (to either a local mirror, or the fastest available internet mirror):::

    class { cobbler::distro::centos63-x86_64:
        http_iso => "http://mirror.facebook.net/centos/6.3/isos/x86_64/CentOS-6.3-x86_64-minimal.iso",
        ks_url   => "cobbler",
    }

* once the configuration is there, Puppet will know that Cobbler must be installed on fuel-pm machine
* It is necessary to note that, in a proposed network configuration, the snippet above includes puppet commands to configure forwarding on cobbler node to make external resources available via 10.0.0.0/24 network which is used during installation process (see “enable_nat_all” and “enable_nat_filter”)
* run puppet agent to actually install Cobbler on fuel-pm
    * ``puppet agent --test``

Testing cobbler
~~~~~~~~~~~~~~~

* you can check that Cobbler is successfully installed by opening the following URL from your host machine:
    * http://10.0.0.100/cobbler_web (u: cobbler, p: cobbler)
* now you have a fully working instance of Cobbler. moreover, “centos63-x86_64” distro and “centos63-x86_64” profile were automatically installed in Cobbler, so that now Cobbler is capable of provisioning CentOS 6.3 on target nodes


Creating your OpenStack cluster
===============================

Creating VMs (fuel-01, fuel-02, and fuel-03)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create three virtual machines for your OpenStack nodes in Virtualbox. Do not start them yet.
* Machine -> New...
    * Name: fuel-01 (will need to repeat for fuel-02 and fuel-03)
    * Type: Linux
    * Version: Red Hat (64 Bit)
* Machine -> Settings... -> Network
    * Adapter 1
        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: en1 (Wi-Fi Airport), or whatever interface where you have internet access 
    * Adapter 2
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet0
    * Adapter 3
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet1
    * Advanced -> Promiscuous mode: Allow All

Configuring cobbler to provision your OpenStack nodes (fuel-01, fuel-02, and fuel-03)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now you need to define nodes in cobbler configuration, so it knows what OS to install where and what configuration actions to take.

On puppet master, create directory with configuration and copy example config file for Cobbler from Fuel repository:::
mkdir cobbler_config
cd cobbler_config
ln -s ../fuel/deployment/puppet/cobbler/examples/cobbler_system.py .
cp ../fuel/deployment/puppet/cobbler/examples/nodes.yaml .


Edit configuration for bare metal provisioning of nodes (nodes.yaml):

* there is essentially a section for every node, and you have to define all nodes there (fuel-01, fuel-02 and fuel-03). the config for one node is posted below. config for the remaining two nodes is very similar
* it’s important to get right the following parameters, they are different for every node (highlighted in bold below)
    * name of the system in cobbler, in the very first line
    * hostname and DNS name
    * mac addresses for every network interface (you can look them up in Virtualbox, using Machine -> Settings... -> Network -> Adapters)
    * static IP address on management interface eth1
* vi nodes.yaml::

    fuel-01:
        profile: "centos63-x86_64"
        netboot-enabled: "1"
        ksmeta: "puppet_auto_setup=1 puppet_master=fuel-pm.mirantis.com puppet_enable=0"
        hostname: "fuel-01.mirantis.com"
        name-servers: "10.0.0.100"
        name-servers-search: "mirantis.com"
        interfaces:
            eth0:
                mac: "08:00:27:AF:04:27"
                static: "0"
            eth1:
                mac: "08:00:27:F5:9A:3C"
                static: "1"
                ip-address: "10.0.0.101"
                netmask: "255.255.255.0"
            eth2:
                mac: "08:00:27:3A:96:C3"
                static: "1"
        interfaces_extra:
            eth0:
                peerdns: "no"
            eth1:
                peerdns: "no"
            eth2:
                promisc: "yes"
                userctl: "yes"
                peerdns: "no"

    fuel-02:
        <the same configuration, with its own parameters for fuel-02>

    fuel-03:
        <the same configuration, with its own parameters for fuel-03>

* for the sake of convenience there is “./cobbler_system.py” script, which reads definition of the systems from the yaml file and makes calls to cobbler API to insert these systems into the configuration. run it using the following command:
    * ``./cobbler_system.py -f nodes.yaml -l DEBUG``

Provisioning your OpenStack nodes using cobbler (fuel-01, fuel-02, and fuel-03)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now, when cobbler has correct configuration, the only thing you need to do is to PXE-boot your nodes. They will boot over network from DHCP/TFTP provided by cobbler and will be provisioned accordingly, with the right operating system and configuration.

Here is what you have to do for every virtual machine (fuel-01, fuel-02 and fuel-03):
* disable bridged network adapter by unchecking  “Machine -> Settings -> Network -> Enable Network Adapter” 
    * the reason for that is --- by default, Virtualbox will attempt to use the first network interface for PXE-boot and it’s going to fail. we actually want our machines to PXE-boot from cobbler, which is on 10.0.0.100 (first host-only adapter). so the solution is to temporarily disable “bridged network adapter”
* Machine -> Start
* press F12 during boot and select “l” (LAN) as a bootable media
* once installation is complete
    * log into the machine (l: root, p: r00tme)
    * perform shutdown using “``shutdown -H now``”
* enable back bridged network adapter by checking  “Machine -> Settings -> Network -> Enable Network Adapter” 
* start the node using Virtualbox
* check that network works correctly
    * ``ping www.google.com``
    * ``ping 10.0.0.100``

It is important to note that if you use VLANs in your network configuration you always have to keep in mind the fact that PXE booting does not work on tagged interfaces. Therefore, all your nodes including the one where cobbler service lives, must share one untagged VLAN (aka native VLAN). You can use dhcp_interface parameter of cobbler::server class to bind dhcp service to definite interface.

Now, you have OS installed and configured on all nodes. Moreover, puppet is installed on the nodes as well and its configuration points to our puppet master. Therefore the nodes are almost ready for deploying OpenStack. Now, as the last step, you need to register nodes in puppet master:
* ``puppet agent --test``
    * it will generate a certificate, send to puppet master for signing, and then fail
* switch to puppet master and execute:
    * ``puppet cert list``
    * ``puppet cert sign --all``
        * alternatively, you can sign only a single certificate using “puppet cert sign fuel-XX.mirantis.com”
* ``puppet agent --test``
    * it should successfully complete and result in “Hello World from fuel-XX” message

Caveats:
~~~~~~~~

#. https://mirantis.jira.com/browse/FUEL-55
    * after the node is installed, you need to manually apply workaround for name resolution, and fix configuration of network interfaces eth0, eth1, and eth2

Installing OpenStack
====================

* save current state of every virtual machine using Virtualbox snapshots (it is helpful to have a point to revert to, so you can install OpenStack using puppet, then revert and try one more time)
* on puppet master
    * get new version of puppet manifests from the repository
        * ``./updateRecipes.sh``
    * create file with definition of networks, nodes, and roles
        * ``cp fuel/deployment/puppet/openstack/examples/site.pp /etc/puppet/manifests/site.pp``
    * ``vi /etc/puppet/manifests/site.pp``

.. note:: <no changes are needed>

* install OpenStack controller on fuel-01
    * run “``puppet agent --test``” on fuel-01
    * wait for installation to complete
* on fuel-02, execute:
    * run “``puppet agent --test``” on fuel-02
    * wait for installation to complete
    * .. important:: it needs to be executed only after fuel-01 installation is complete, due to the nature of assembling MySQL cluster based on Galera

Common issues
=============

#. Puppet fails with “err: Could not retrieve catalog from remote server: Error 400 on SERVER: undefined method 'fact_merge' for nil:NilClass”
    * bug: http://projects.puppetlabs.com/issues/3234
    * workaround: “service puppetmaster restart”
#. Puppet client will never resend certificate to puppet master. Certificate cannot be signed and verified.
    * bug: http://projects.puppetlabs.com/issues/4680
    * workaround:
        * on puppet client: “``rm -f /etc/puppet/ssl/certificate_requests/\*.pem``”, and “``rm -f /etc/puppet/ssl/certs/\*.pem``”
        * on puppet master: “``rm -f /var/lib/puppet/ssl/ca/requests/\*.pem``”

#. My manifests are up to date under /etc/puppet/manifests, but puppet master keeps serving previous version of manifests to the clients. Manifests seem to be cached by puppet master.
    * issue: https://groups.google.com/forum/?fromgroups=#!topic/puppet-users/OpCBjV1nR2M
    * workaround: “``service puppetmaster restart``”
#. You may get timeout error for fuel-0x when running puppet-agent --test to install openstack when using HDD instead of SSD
    * Sep 26 17:56:15 fuel-02 puppet-agent[1493]: Could not retrieve catalog from remote server: execution expired
    Sep 26 17:56:15 fuel-02 puppet-agent[1493]: Not using cache on failed catalog
    Sep 26 17:56:15 fuel-02 puppet-agent[1493]: Could not retrieve catalog; skipping run
    * workaround: ``vi /etc/puppet/puppet.conf``
        * add: ``configtimeout = 1200``
#. while running "``puppet agent --test``" error messages below can occur:
    * err: /File[/var/lib/puppet/lib]: Could not evaluate: Could not retrieve information from environment production source(s) puppet://fuel-pm.mirantis.com/plugins
    and
    err: Could not retrieve catalog from remote server: Error 400 on SERVER: stack level too deep
    warning: Not using cache on failed catalog
    err: Could not retrieve catalog; skipping run
    * The first problem can be solved using the way discribed here http://projects.reductivelabs.com/issues/2244
    * The second problem can be solved by rebooting puppet-master

