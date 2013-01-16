
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
  
  * Change IP addresses for "public" and "internal" according to your networking requirements

      $internal_virtual_ip = '10.0.0.253' # IP address must be in address space of management network (eth0)

      $public_virtual_ip   = '10.xxx.yyy.253' # must be in address space of public network (eth1) , but not in DHCP range and floating range (see below). 

  * Define "$floating_range" and "$fixed_range" accordingly

      $floating_range  = '10.xxx.yyy.128/26' # IP-address from the public address space. 
      $fixed_range     = '10.0.198.0/24'     # This subnet used for service purpose only. Specify any unused by you subnet here. 

  * Specify network manager.  It can be 'nova.network.manager.FlatDHCPManager', 'nova.network.manager.FlatManager' or 'nova.network.manager.VlanManager'

      $network_manager = 'nova.network.manager.FlatDHCPManager'

  * Define how many networks to be created at once

      $num_networks    = 1     # Number of networks to create
      $network_size    = 255   # Number of IPs per network
      $vlan_start      = 300   # VLAN ID to start with (the VLAN IDs from ``vlan_start`` to ``vlan_start + num_networks-1`` are generated automatically)

**Note:**
The last options above are specific to nova network and will be ignored if the quantum service is enabled

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


Enabling Cinder
^^^^^^^^^^^^^^^

* In order to deploy OpenStack with Cinder, simply set ``$cinder = true`` in your site.pp file.
* Then, specify the list of physical devices in ``$nv_physical_volume``. They will be aggregated into "cinder-volumes" volume group.
* Alternatively, you can leave this field blank and create LVM VolumeGroup called "cinder-volumes" on every controller node yourself. Cobbler automation allows you to create this volume group during bare metal provisioning phase through parameter "cinder_bd_for_vg" in nodes.yaml file.
* The available manifests under "examples" assume that you have the same collection of physical devices for VolumeGroup "cinder-volumes" across all of your volume nodes.
* Cinder will be activated on any node that contains ``$nv_phyical_volume`` block device(s) or "cinder-volumes" volume group, including both controller and compute nodes.
* Be careful to not add block devices to the list which contain useful data (e.g. block devices on which your OS resides), as they will be destroyed after you allocate them for Cinder.
* For example::

       # Volume manager: cinder(true) or nova-volume(false)
       $cinder             = true

       # Rather cinder/nova-volume (iscsi volume driver) should be enabled
       $manage_volumes     = true

       # Disk or partition for use by cinder/nova-volume
       # Each physical volume can be a disk partition, whole disk, meta device, or loopback file
       $nv_physical_volume = ['/dev/sdz', '/dev/sdy', '/dev/sdx']


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

* Your OpenStack cluster is ready to go.

Note: Due to the Swift setup specifics, it is not enough to run Puppet 1 time. To complete the deployment, you should perform 3 runs of Puppet on each node.
