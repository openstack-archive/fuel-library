.. _Install-OS-Using-Fuel:

Installing the OS using Fuel
----------------------------

The first step in creating the actual OpenStack nodes is to let Fuel's Cobbler kickstart and preseed files assist in the installation of operating systems on the target servers.


.. _Configuring-Cobbler:

Configuring Cobbler with config.yaml
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Fuel uses a single file, ``config.yaml``, to both configure Cobbler and assist in the configuration of the ``site.pp`` file.  This file appears in the ``/root`` directory when the master node (fuel-pm) is provisioned and configured.

You'll want to configure this example for your own situation, but the example looks like this::

  common:
    orchestrator_common:
      attributes:
        deployment_mode: ha_compact
        deployment_engine: simplepuppet
      task_uuid: deployment_task

Possible values for ``deployment_mode`` are ``singlenode_compute``, ``multinode_compute``, ``ha_compute``, ``ha_compact``, ``ha_full``, and ``ha_minimal``.  Change the ``deployment_mode`` to ``ha_compact`` to tell Fuel to use HA architecture.  Specifying the ``simplepuppet`` deployment engine means that the orchestrator will be calling Puppet on each of the nodes.

Next you'll need to set OpenStack's networking information::

    openstack_common:
     internal_virtual_ip: 10.0.0.10
     public_virtual_ip: 192.168.0.10
     create_networks: true
     fixed_range: 172.16.0.0/16
     floating_range: 192.168.0.0/24

Change the virtual IPs to match the target networks, and set the fixed and floating ranges. ::

     swift_loopback: loopback
     nv_physical_volumes:
      - /dev/sdb

By setting the ``nv_physical_volumes`` value, you are not only telling OpenStack to use this value for Cinder (you'll see more about that in the ``site.pp`` file), but also where Cinder should store its data.

Later, we'll set up a new partition for Cinder, so tell Cobbler to create it here. ::

   external_ip_info:
     public_net_router: 192.168.0.1
     ext_bridge: 0.0.0.0
     pool_start: 192.168.0.110
     pool_end: 192.168.0.126

Set the ``public_net_router`` to point to the real router at the public network.  The ``ext_bridge`` is the IP of the Quantum bridge. It should assigned to any available free IP on the public network that's outside the floating range.  You also have the option to simply set it to ``0.0.0.0``.  The ``pool_start`` and ``pool_end`` values represent the public addresses of your nodes, and should be within the ``floating_range``. ::

   segment_range: 900:999
   network_manager: nova.network.manager.FlatDHCPManager
   auto_assign_floating_ip: true
   quantum_netnode_on_cnt: true   

Fuel provides two choices for your network manager: FlatDHCPManager, and VlanManager.  By default, the system uses FlatDHCPManager.  Here you can see that we're also telling OpenStack to automatically assing a floating IP to an instance when it's created, and to put the Quantum services on the controllers rather than a sepearate node.You can also choose ``tenant_network_type`` for network segmentation type and  segmentation range ``segment_range``  for network (consult Quantum documentation for details). ::

   use_syslog: false
   syslog_server: 127.0.0.1
   mirror_type: default

**THIS SETTING IS CRUCIAL:** The ``mirror_type`` **must** to be set to ``default`` unless you have your own repositories set up, or OpenStack will not install properly. ::

   quantum: true
   internal_interface: eth0
   public_interface: eth1
   private_interface: eth2
   public_netmask: 255.255.255.0
   internal_netmask: 255.255.255.0

Earlier, you decided which interfaces to use for which networks; note that here. ::

   default_gateway: 192.168.0.1

Depending on how you've set up your network, you can either set the ``default_gateway`` to the master node (fuel-pm) or to the ``public_net_router``. ::

   nagios_master: fuel-controller-01.localdomain
   loopback: loopback
   cinder: true
   cinder_nodes:
   - controller
   swift: true

The loopback setting determines how Swift stores data. If you set the value to ``loopback``, Swift will use 1gb files as storage devices. If you tuned Cobbler to create a partition for Swift and mounted it to ``/srv/nodes/``, then you should set ``loopback`` to ``false``.   
   
In this example, you're using Cinder and including it on the compute nodes, so note that appropriately.  Also, you're using Swift, so turn that on here. ::

   repo_proxy: http://10.0.0.100:3128

One improvement in Fuel 2.1 was the ability for the master node to cache downloads in order to speed up installs; by default the ``repo_proxy`` is set to point to fuel-pm in order to let that happen.  One consequence of that is that your deployment will actually go faster if you let one install complete, then do all the others, rather than running all of them concurrently. ::

   deployment_id: '53'

Fuel enables you to manage multiple clusters; setting the ``deployment_id`` will let Fuel know which deployment you're working with. ::

   dns_nameservers:
   - 10.0.0.100
   - 8.8.8.8

The slave nodes should first look to the master node for DNS, so mark that as your first nameserver.

The next step is to define the nodes themselves.  To do that, you'll list each node once for each role that needs to be installed.  Note that by default the first node is called ``fuel-cobbler``; change it to ``fuel-pm``. ::

   nodes:
   - name: fuel-pm
     role: cobbler
     internal_address: 10.0.0.100
     public_address: 192.168.0.100
   - name: fuel-controller-01
     role: controller
     internal_address: 10.0.0.101
     public_address: 192.168.0.101
     swift_zone: 1
   - name: fuel-controller-02
     role: controller
     internal_address: 10.0.0.102
     public_address: 192.168.0.102
     swift_zone: 2
   - name: fuel-controller-03
     role: controller
     internal_address: 10.0.0.103
     public_address: 192.168.0.103
     swift_zone: 3
   - name: fuel-controller-01
     role: quantum
     internal_address: 10.0.0.101
     public_address: 192.168.0.101
   - name: fuel-compute-01
     role: compute
     internal_address: 10.0.0.110
     public_address: 192.168.0.110

Notice that each node can be listed multiple times; this is because each node fulfills multiple roles.  Notice also that the IP address for fuel-compute-01 is *.110, not *.105.

The ``cobbler_common`` section applies to all machines::

  cobbler_common:
    # for Centos
    profile: "centos64_x86_64"
    # for Ubuntu
    # profile: "ubuntu_1204_x86_64"

Fuel can install CentOS or Ubuntu on your servers, or you can add a profile of your own. By default, ``config.yaml`` uses CentOS. ::

    netboot-enabled: "1"
    # for Ubuntu
    # ksmeta: "puppet_version=2.7.19-1puppetlabs2 \
    # for Centos
    name-servers: "10.0.0.100"
    name-servers-search: "localdomain"
    gateway: 192.168.0.1

Set the default nameserver to be fuel-pm, and change the domain name to your own domain name.  Set the ``gateway`` to the public network's default gateway. Alternatively, if you don't plan to use your public networks actual gateway, you can set this value to be the IP address of the master node. 

**Please note:** You must specify a working gateway (or proxy) in order to install OpenStack, because the system will need to communicate with public repositories. ::

    ksmeta: "puppet_version=2.7.19-1puppetlabs2 \
      puppet_auto_setup=1 \
      puppet_master=fuel-pm.localdomain \

Change the fully-qualified domain name for the Puppet Master to reflect your own domain name. ::

      puppet_enable=0 \
      ntp_enable=1 \
      mco_auto_setup=1 \
      mco_pskey=un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi \
      mco_stomphost=10.0.0.100 \

Make sure the ``mco_stomphost`` is set for the master node so that the orchestrator can find the nodes. ::

      mco_stompport=61613 \
      mco_stompuser=mcollective \
      mco_stomppassword=AeN5mi5thahz2Aiveexo \
      mco_enable=1"

This section sets the system up for orchestration; you shouldn't have to touch it.

Next you'll define the actual servers. ::

	fuel-controller-01:
	  hostname: "fuel-controller-01"
	  role: controller
	  interfaces:
	    eth0:
	      mac: "08:00:27:BD:3A:7D"
	      static: "1"
	      ip-address: "10.0.0.101"
	      netmask: "255.255.255.0"
	      dns-name: "fuel-controller-01.localdomain"
	      management: "1"
	    eth1:
	      mac: "08:00:27:ED:9C:3C"
	      static: "0"
	    eth2:
	      mac: "08:00:27:B0:EB:2C"
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

For a VirtualBox installation, you can retrieve the MAC ids for your network adapters by expanding "Advanced" for the adapater in VirtualBox, or by executing ifconfig on the server itself.  

For a physical installation, the MAC address of the server is often printed on the sticker attached to the server for the LOM interfaces, or is available from the BIOS screen.  You may also be able to find the MAC address in the hardware inventory BMC/DRAC/ILO, though this may be server-dependent.

Also, make sure the ``ip-address`` is correct, and that the ``dns-name`` has your own domain name in it.

In this example, IP addresses should be assigned as follows::

    fuel-controller-01:  10.0.0.101
    fuel-controller-02:  10.0.0.102
    fuel-controller-03:  10.0.0.103
    fuel-compute-01:     10.0.0.110

Repeat this step for each of the other controllers, and for the compute node.  Note that the compute node has its own role::

	fuel-compute-01:
	  hostname: "fuel-compute-01"
	  role: compute
	  interfaces:
	    eth0:
	      mac: "08:00:27:AE:A9:6E"
	      static: "1"
	      ip-address: "10.0.0.110"
	      netmask: "255.255.255.0"
	      dns-name: "fuel-compute-01.localdomain"
	      management: "1"
	    eth1:
	      mac: "08:00:27:B7:F9:CD"
	      static: "0"
	    eth2:
	      mac: "08:00:27:8B:A6:B7"
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
  

Loading the configuration
^^^^^^^^^^^^^^^^^^^^^^^^^

Once you've completed the changes to ``config.yaml``, you need to load the information into Cobbler.  To do that, use the ``cobbler_system`` script::

   cobbler_system -f config.yaml

Now you're ready to start spinning up the controllers and compute nodes.

Installing the operating system
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that Cobbler has the correct configuration, the only thing you
need to do is to PXE-boot your nodes. This means that they will boot over the network, with
DHCP/TFTP provided by Cobbler, and will be provisioned accordingly,
with the specified operating system and configuration.

If you installed Fuel from the ISO, start fuel-controller-01 first and let the installation finish before starting the other nodes; Fuel will cache the downloads so subsequent installs will go faster.

The process for each node looks like this:


#. Start the VM.
#. Press F12 immediately and select l (LAN) as a bootable media.
#. Wait for the installation to complete.
#. Log into the new machine using root/r00tme.
#. **Change the root password.**
#. Check that networking is set up correctly and the machine can reach the Internet::

    ping fuel-pm.localdomain
    ping www.mirantis.com

If you're unable to ping outside addresses, add the fuel-pm server as a default gateway::

    route add default gw 10.0.0.100

**It is important to note** that if you use VLANs in your network
configuration, you always have to keep in mind the fact that PXE
booting does not work on tagged interfaces. Therefore, all your nodes,
including the one where the Cobbler service resides, must share one
untagged VLAN (also called native VLAN). If necessary, you can use the
``dhcp_interface`` parameter of the ``cobbler::server`` class to bind the DHCP
service to the appropriate interface.


