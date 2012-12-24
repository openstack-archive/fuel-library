
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
    * create a file with the definition of networks, nodes, and roles. Assume you are deploying a compact configuration, with Controllers and Swift combined:
        * ``cp /etc/puppet/modules/openstack/examples/site_openstack_swift_compact.pp /etc/puppet/manifests/site.pp``
    * ``vi /etc/puppet/manifests/site.pp`` and edit settings accordingly (see "Configuring Network", "Enabling Quantum", "Enabling Cinder" below):
       
       .. literalinclude:: ../../deployment/puppet/openstack/examples/site_openstack_swift_compact_fordocs.pp
    
    * create a directory with keys, give it appropriate permissions, and generate keys themselves
        * ``mkdir /var/lib/puppet/ssh_keys``
        * ``cd /var/lib/puppet/ssh_keys``
        * ``ssh-keygen -f openstack``
        * ``chown -R puppet:puppet /var/lib/puppet/ssh_keys/``
    * edit file ``/etc/puppet/fileserver.conf`` and append the following lines: :: 
    
        [ssh_keys]
        path /var/lib/puppet/ssh_keys
        allow *

Configuring Network
^^^^^^^^^^^^^^^^^^^

* You will need to change the following parameters:
  
  * Change IP addresses for "public" and "internal" according to your networking requirements
  * Define "$floating_range" and "$fixed_range" accordingly

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
* Alternatively, you can leave this field blank and create LVM VolumeGroup called "cinder-volumes" on every controller node yourself.
* The available manifests under "examples" assume that you have the same collection of physical devices for VolumeGroup "cinder-volumes" across all of your volume nodes.
* Be careful and do not add block devices to the list containing useful data (e.g. block devices on which your OS resides), as they will be destroyed after you allocate them for Cinder.
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
