
Deploying OpenStack
-------------------

Initial setup
~~~~~~~~~~~~~

If you are using hardware, make sure it is capable of PXE booting over the network from Cobbler.

In case of VirtualBox, create the corresponding virtual machines for your OpenStack nodes. Do not start them yet.

* Machine -> New...
    * Name: fuel-controller-01 (will need to repeat for fuel-controller-02, fuel-controller-03, and fuel-compute-01)
    * Type: Linux
    * Version: Red Hat (64 Bit) or Ubuntu (64 Bit)

* Machine -> System -> Motherboard...
    * Check "Network" in "Boot sequence"

* Machine -> Settings... -> Network
    * Adapter 1
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet0
    
    * Adapter 2
        * Enable Network Adapter
        * Attached to: Bridged Adapter
        * Name: en1 (Wi-Fi Airport), or whatever network interface of the host machine with Internet access 

    * Adapter 3
        * Enable Network Adapter
        * Attached to: Host-only Adapter
        * Name: vboxnet1
        * Advanced -> Promiscuous mode: Allow All

    * It is important that host-only "Adapter 1" goes first, as Cobbler will use vboxnet0 for PXE, and VirtualBox boots from LAN on the first available network adapter.

Configuring nodes in Cobbler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now you need to define nodes in the Cobbler configuration, so that it knows what OS to install, where to install it, and what configuration actions to take.

On Puppet master, create a directory for configuration (wherever you like) and copy the sample config file for Cobbler from Fuel repository:

    * ``mkdir cobbler_config``
    * ``cd cobbler_config``
    * ``cp /etc/puppet/modules/cobbler/examples/cobbler_system.py .``
    * ``cp /etc/puppet/modules/cobbler/examples/nodes.yaml .``

Edit configuration for bare metal provisioning of nodes (nodes.yaml):

* There is essentially a section for every node, and you have to define all OpenStack nodes there (fuel-controller-01, fuel-controller-02, fuel-controller-03, and fuel-compute-01 by default). The config for a single node is provided below. The config for the remaining nodes is very similar
* It is important to get the following parameters correctly specified (they are different for every node):
    * name of the system in Cobbler, the very first line
    * hostname and DNS name (do not forget to replace "your-domain-name.com" with your domain name)
    * MAC addresses for every network interface (you can look them up in VirtualBox by using Machine -> Settings... -> Network -> Adapters)
    * static IP address on management interface eth0
	* version of Puppet according target OS
* vi nodes.yaml
    .. literalinclude:: ../../deployment/puppet/cobbler/examples/nodes.yaml

* for the sake of convenience the "./cobbler_system.py" script is provided. The script reads the definition of the systems from the yaml file and makes calls to Cobbler API to insert these systems into the configuration. Run it using the following command:
    * ``./cobbler_system.py -f nodes.yaml -l DEBUG``

Installing OS on the nodes using Cobbler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now, when Cobbler has the correct configuration, the only thing you need to do is to PXE-boot your nodes. They will boot over the network from DHCP/TFTP provided by Cobbler and will be provisioned accordingly, with the specified operating system and configuration.

In case of VirtualBox, here is what you have to do for every virtual machine (fuel-controller-01, fuel-controller-02, fuel-controller-03, fuel-compute-01):

* Start VM
* Press F12 immediately and select "l" (LAN) as a bootable media
* Wait for the installation to complete
* Check that network is set up correctly and machine can reach package repositories as well as Puppet master
    * ``ping download.mirantis.com``
    * ``ping fuel-pm.your-domain-name.com``

It is important to note that if you use VLANs in your network configuration, you always have to keep in mind the fact that PXE booting does not work on tagged interfaces. Therefore, all your nodes including the one where the Cobbler service resides must share one untagged VLAN (also called "native VLAN"). You can use the ``dhcp_interface`` parameter of the ``cobbler::server`` class to bind the DHCP service to a certain interface.

Now you have OS installed and configured on all nodes. Moreover, Puppet is installed on the nodes as well and its configuration points to our Puppet master. Therefore, the nodes are almost ready for deploying OpenStack. Now, as the last step, you need to register nodes in Puppet master:

* ``puppet agent --test``
    * it will generate a certificate, send to Puppet master for signing, and then fail
* switch to Puppet master and execute:
    * ``puppet cert list``
    * ``puppet cert sign --all``
        * alternatively, you can sign only a single certificate using "puppet cert sign fuel-XX.your-domain-name.com"
* ``puppet agent --test``
    * it should successfully complete and result in the "Hello World from fuel-XX" message

Configuring OpenStack cluster in Puppet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In case of VirtualBox, it is recommended to save the current state of every virtual machine using the mechanism of snapshots. It is helpful to have a point to revert to, so that you could install OpenStack using Puppet and then revert and try one more time, if necessary.

* On Puppet master
    * edit file ``/etc/puppet/fileserver.conf`` and append the following lines: :: 
    
        [ssh_keys]
        path /var/lib/puppet/ssh_keys
        allow *

    * create a directory with keys, give it appropriate permissions, and generate keys themselves
        * ``mkdir /var/lib/puppet/ssh_keys``
        * ``cd /var/lib/puppet/ssh_keys``
        * ``ssh-keygen -f openstack``
        * ``chown -R puppet:puppet /var/lib/puppet/ssh_keys/``
    * create a file with the definition of networks, nodes, and roles. Assume you are deploying a compact configuration, with Controllers and Swift combined:
        ``cp /etc/puppet/modules/openstack/examples/site_openstack_swift_compact.pp /etc/puppet/manifests/site.pp``
    * ``vi /etc/puppet/manifests/site.pp`` and edit settings accordingly (see "Configuring Network", "Enabling Quantum", "Enabling Cinder" below):
       
       .. literalinclude:: ../../deployment/puppet/openstack/examples/site_openstack_swift_compact_fordocs.pp
    

Configuring Network
^^^^^^^^^^^^^^^^^^^

* You will need ``vi /etc/puppet/manifests/site.pp`` (see above) to change the following parameters:
  
  * Change IP addresses for "public" and "internal" according to your networking requirements::

    $internal_virtual_ip = '10.0.0.253' # IP address must be in address space of management network (eth0)
    $public_virtual_ip   = '10.xxx.yyy.253' # must be in address space of public network (eth1) , but not in DHCP range and floating range (see below). 

  * Define "$floating_range" and "$fixed_range" accordingly::

    $floating_range  = '10.xxx.yyy.128/26' # IP-address from the public address space. 
    $fixed_range     = '10.0.198.0/24'     # This subnet used for service purpose only. Specify any unused by you subnet here. 

  * Specify network manager.  It can be 'nova.network.manager.FlatDHCPManager', 'nova.network.manager.FlatManager' or 'nova.network.manager.VlanManager'::

    $network_manager = 'nova.network.manager.FlatDHCPManager'

  * Define how many networks to be created at once::

    $num_networks  = 1     # Number of networks to create
    $network_size  = 255   # Number of IPs per network
    $vlan_start    = 300   # VLAN ID to start with
    IDs from (vlan_start) to (vlan_start + num_networks-1) are generated automatically

  **Note:**
  The last options are specific to nova network and will be ignored if the quantum service is enabled

Configuring for Syslog
^^^^^^^^^^^^^^^^^^^^^^

* If you want to use syslog server, you need to do the following steps:

Set $use_syslog variable to true in site.pp

Adjust corresponding variables in "if $use_syslog" clause

::

    $use_syslog = true
         if $use_syslog {
            class { "::rsyslog::client": 
                log_local => true,
                log_auth_local => true,
                server => '127.0.0.1',
                port => '514'
            }
    }


For remote logging:

            server => <syslog server hostname or ip>

            port => <syslog server port>

For local logging:

            set log_local and log_auth_local to true

Configuring Rate-Limits
^^^^^^^^^^^^^^^^^^^^^^^

Openstack has predefined limits on different HTTP queries for nova-compute and cinder services. Sometimes (e.g. for big clouds or test scenarios) these limits are too strict. (See http://docs.openstack.org/folsom/openstack-compute/admin/content/configuring-compute-API.html) In this case you can change them to appropriate values. 

There are to hashes describing these limits: $nova_rate_limits and $cinder_rate_limits. ::

    $nova_rate_limits = { 'POST' => '10',
    'POST_SERVERS' => '50',
    'PUT' => 10, 'GET' => 3,
    'DELETE' => 100 }

    $cinder_rate_limits = { 'POST' => '10',
    'POST_SERVERS' => '50',
    'PUT' => 10, 'GET' => 3,
    'DELETE' => 100 }

Enabling Quantum
^^^^^^^^^^^^^^^^

* In order to deploy OpenStack with Quantum you need to setup an additional node that will act as a L3 router. This node is defined in configuration as ``fuel-quantum`` node. You will need to set the following options in order to enable Quantum::

        # Network mode: quantum(true) or nova-network(false)
        $quantum                = true

        # API service location
        $quantum_host           = $internal_virtual_ip

        # Keystone and DB user password
        $quantum_user_password  = 'quantum_pass'
        $quantum_db_password    = 'quantum_pass'

        # DB user name
        $quantum_db_user        = 'quantum'

        # Type of network to allocate for tenant networks.
        # You MUST either change this to 'vlan' or change this to 'gre'
        # in order for tenant networks to provide connectivity between hosts
        # Sometimes it can be handy to use GRE tunnel mode since you don't have to configure your physical switches for VLANs
        $tenant_network_type    = 'gre'

        # For VLAN networks, the VLAN VID on the physical network that realizes the virtual network.
        # Valid VLAN VIDs are 1 through 4094.
        # For GRE networks, the tunnel ID.
        # Valid tunnel IDs are any 32 bit unsigned integer.
        $segment_range          = '1500:1999'

Mirror choosing
^^^^^^^^^^^^^^^

At present we can have several types of mirrors for package downloading. One can either use external repos provided by Mirantis and your distribution vendors or use internal repos. This behavior is controlled by $mirror_type variable in site.pp. Set it to 'external' - as of version 2.0 it is not possible to define custom internal repo, but it will be possible in future versions. Anyway, you can modify mirantis_repos.pp to run with your internal repo.

Enabling Cinder
^^^^^^^^^^^^^^^

* In order to deploy OpenStack with Cinder, simply set ``$cinder = true`` in your site.pp file.
* If you need export cinder volumes from compute nodes (not only from controller nodes), set ``$cinder_on_computes = true`` in your site.pp file.
* Then, specify the list of physical devices in ``$nv_physical_volume``. They will be aggregated into "cinder-volumes" volume group.
* Alternatively, you can leave this field blank and create LVM VolumeGroup called "cinder-volumes" on every controller node yourself. Cobbler automation allows you to create this volume group during bare metal provisioning phase through parameter "cinder_bd_for_vg" in nodes.yaml file.
* The available manifests under "examples" assume that you have the same collection of physical devices for VolumeGroup "cinder-volumes" across all of your volume nodes.
* Cinder will be activated on any node that contains ``$nv_phyical_volume`` block device(s) or "cinder-volumes" volume group, including both controller and compute nodes.
* Be careful to not add block devices to the list which contain useful data (e.g. block devices on which your OS resides), as they will be destroyed after you allocate them for Cinder.
* You can specify network interface, that will be used for exports cinder volumes (by default used management network interface). For this set ``$cinder_iscsi_bind_iface = 'ethX'`` option.
* For example::

       # Volume manager: cinder(true) or nova-volume(false)
       $cinder             = true
       $cinder_on_computes = true

       # Setup network interface, which Cinder used for export iSCSI targets.
       $cinder_iscsi_bind_iface = 'ethX'

       # Rather cinder/nova-volume (iscsi volume driver) should be enabled
       $manage_volumes     = true

       # Disk or partition for use by cinder/nova-volume
       # Each physical volume can be a disk partition, whole disk, meta device, or loopback file
       $nv_physical_volume = ['/dev/sdz', '/dev/sdy', '/dev/sdx']

.. _create-the-XFS-partition:

Enabling Swift
^^^^^^^^^^^^^^^
The following options should be changed if necessary: ::

  # make a backend selection (file or swift) 
  $glance_backend = 'swift'
  
  # 'loopback' for testing (it creates two loopback devices on every node)
  # false for pre-built devices
  $swift_loopback = 'loopback'
  
  # defines where to place the ringbuilder 
  $swift_master = 'fuel-swiftproxy-01'
  
  # all of the swift services, rsync daemon on the storage nodes listen on their local net ip addresses
  $swift_local_net_ip = $internal_address
 

In ``openstack/examples/site_openstack_swift_standalone.pp`` example, the following nodes are specified:

* fuel-swiftproxyused as the ringbuilder + proxy node
* fuel-swift-01, fuel-swift-02, fuel-swift-03 used as the storage nodes

In ``openstack/examples/site_openstack_swift_compact.pp`` example, the role of swift-storage and swift-proxy combined with controllers.

For more realistic use-cases, you should manually prepare volumes by fdisk and initialize it:


* create the XFS partition:

  ``mkfs.xfs -i size=1024 -f /dev/sdx1``

* mount device/partition:

  For a standard swift install, all data drives are mounted directly under ``/srv/node``

  ``mount -t xfs -o noatime,nodiratime,nobarrier,logbufs=8 /dev/sdx1 /srv/node/sdx``


Installing OpenStack on the nodes using Puppet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Install OpenStack controller nodes sequentially, one by one
    * run "``puppet agent --test``" on fuel-controller-01
    * wait for the installation to complete
    * repeat the same for fuel-controller-02 and fuel-controller-03
    * .. important:: It is important to establish the cluster of OpenStack controllers in sequential fashion, due to the nature of assembling MySQL cluster based on Galera

* Install OpenStack compute nodes. You can do it in parallel if you wish.
    * run "``puppet agent --test``" on fuel-compute-01
    * wait for the installation to complete

* Install Swift nodes in standalone/compact mode.

  To fully configure a Swift environment, the nodes must be configured in the following order:

    * First the storage nodes need to be configured.
      This creates the storage services (object, container, account) and exports all of the storage endpoints
      for the ring builder into puppetDB.
      **Note:** The replicator service fails to start in this initial configuration. It is Ok.

    * Next, the ringbuild and swift proxy must be configured.
      The ringbuilder needs to collect the storage endpoints and create the ring database before the proxy
      can be installed. It also sets up an rsync server which is used to host the ring database.
      Resources are exported that are used to rsync the ring database from this server.

    * Finally, the storage nodes should be run again so that they can rsync the ring databases.

  **Note:** In compact mode, as storage and proxy services are on the same node, to complete the deployment, you should perform 2 runs of Puppet on each node (run it once on all 3 controllers, then a second time on each controller). But if you are using loopback devices it requires to run a third time.

* Your OpenStack cluster is ready to go.

Installing Nagios Monitoring using Puppet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Installing nagios NRPE on compute or controller node: ::
  class {'nagios':
  proj_name       => 'test',
  services        => ['nova-compute','nova-network','libvirt'],
  whitelist       => ['127.0.0.1','10.0.97.5'],
  hostgroup       => 'compute',
  }

where ``proj_name`` is a env for nagios commands and directory
in this case:
        "``/etc/nagios/test/``"
``ervices`` - all services which nagios will monitor
``whitelist`` - array of IP addreses which NRPE trusts
``hostgroup`` - group wich will use in nagios master (do not forget create it in nagios master)

Installing nagios Master on any convenient node: ::

  class {'nagios::master':
    proj_name       => 'test',
    templatehost    => {'name' => 'default-host','check_interval' => '10'},
    templateservice => {'name' => 'default-service' ,'check_interval'=>'10'},
    hostgroups      => ['compute','controller'],
    contactgroups   => {'group' => 'admins', 'alias' => 'Admins'}, 
    contacts        => {'user' => 'hotkey', 'alias' => 'Dennis Hoppe',
                 'email' => 'nagios@%{domain}',
                 'group' => 'admins'},
  }

where ``proj_name`` is a env for nagios services and directory
in this case:
        "``/etc/nagios3/test/``"
``templatehost`` - group of checks and intervals parameters for hosts (as Hash)
``templateservice`` - group checks and intervals parameters for services  (as Hash)
``hostgroups`` - just add all of groups which were on NRPE nodes (as Array)
``contactgroups`` - group of contacts {as Hash}
``contacts`` - create contacts for send error reports {as Hash}


Examples of OpenStack installation sequences
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**First, please see the link below for details about different deployment scenarios.**

     :ref:`Swift-and-object-storage-notes`

  **Note:** No changes to ``site.pp`` necessary between installation phases except the *Controller + Compute on the same node* case. You simply run the same puppet scenario in several passes over the already installed node. Every deployment pass Puppet collects and adds necessary absent information to OpenStack configuration, stores it to PuppedDB and applies necessary changes. But please use appropriate ``site.pp`` from OpenStack Examples as base file for your OpenStack deployment.

  **Note:** *Sequentially run* means you don't start the next node deployment until previous one is finished.

  **Example1:** **Full OpenStack deployment with standalone storage nodes**

    * Create necessary volumes on storage nodes as described in	 :ref:`create-the-XFS-partition`
    * Sequentially run deployment pass on controller nodes (``fuel-controller-01 ... fuel-controller-xx``).
    * Run additional deployment pass on Controller 1 only (``fuel-controller-01``) to finalize Galera cluster configuration.
    * Run deployment pass on every compute node (``fuel-compute-01 ... fuel-compute-xx``) - unlike controllers these nodes may be deployed in parallel.
    * Sequentially run deployment pass on every storage node (``fuel-sowift-01`` ... ``fuel-swift-xx``) node. By default these nodes named as ``fuel-swift-xx``. Errors in Swift storage like */Stage[main]/Swift::Storage::Container/Ring_container_device[<device address>]: Could not evaluate: Device not found check device on <device address>* are expected on Storage nodes during the deployment passes until the very final pass.
    * In case loopback devices are used on storage nodes (``$swift_loopback = 'loopback'`` in ``site.pp``) - run deployment pass on every storage (``fuel-swift-01`` ... ``fuel-swift-xx``) node one more time. Skip this step in case loopback is off (``$swift_loopback = false`` in ``site.pp``). Again, ignore errors in *Swift::Storage::Container* during this deployment pass.
    * Run deployment pass on every SwiftProxy node (``fuel-swiftproxy-01 ... fuel-swiftproxy-02``). Node names are set by ``$swift_proxies`` variable in ``site.pp``. There are 2 Swift Proxies by default.
    * Repeat deployment pass on every storage (``fuel-swift-01`` ... ``fuel-swift-xx``) node. No Swift storage errors should appear during this deployment pass!

  **Example2:** **Compact OpenStack deployment with storage and swift-proxy combined with nova-controller on the same nodes**

    * Create necessary volumes on controller nodes as described in	 :ref:`create-the-XFS-partition`
    * Sequentially run deployment pass on controller nodes (``fuel-controller-01 ... fuel-controller-xx``). Errors in Swift storage like */Stage[main]/Swift::Storage::Container/Ring_container_device[<device address>]: Could not evaluate: Device not found check device on <device address>* are expected during the deployment passes until the very final pass.
    * Run deployment pass on every compute node (``fuel-compute-01 ... fuel-compute-xx``) - unlike controllers these nodes may be deployed in parallel.
    * Sequentially run one more deployment pass on every controller (``fuel-controller-01 ... fuel-controller-xx``) node. Again, ignore errors in *Swift::Storage::Container* during this deployment pass.
    * Run additional deployment pass *only* on controller, which holds on the SwiftProxy service. By default it is ``fuel-controller-01``. And again, ignore errors in *Swift::Storage::Container* during this deployment pass.
    * Sequentially run one more deployment pass on every controller (``fuel-controller-01 ... fuel-controller-xx``) node to finalize storage configuration. No Swift storage errors should appear during this deployment pass!

  **Example3:** **OpenStack HA installation without Swift**

    * Sequentially run deployment pass on controller nodes (``fuel-controller-01 ... fuel-controller-xx``). No errors should appear during this deployment pass.
    * Run additional deployment pass on Controller 1 only (``fuel-controller-01``) to finalize Galera cluster configuration.
    * Run deployment pass on every compute node (``fuel-compute-01 ... fuel-compute-xx``) - unlike controllers these nodes may be deployed in parallel.

  **Example4:** **The most simple OpenStack installation Controller + Compute on the same node**

    * Set ``node /fuel-controller-[\d+]/`` variable in ``site.pp`` to match with node name you are going to deploy OpenStack. Set ``node /fuel-compute-[\d+]/`` variable to **mismatch** with node name. Run deployment pass on this node. No errors should appear during this deployment pass.
    * Set ``node /fuel-compute-[\d+]/`` variable in ``site.pp`` to match with node name you are going to deploy OpenStack. Set ``node /fuel-controller-[\d+]/`` variable to **mismatch** with node name. Run deployment pass on this node. No errors should appear during this deployment pass.
