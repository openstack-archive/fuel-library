Configuring Cobbler
-------------------

(NOTE:  This section is a draft and is awaiting final testing before completion.)

Fuel uses a single file, config.yaml, to both configure Cobbler and assist in the configuration of the site.pp file.  An example of this file will be distributed with later versions of Fuel, but in the meantime, you can use this file as an example:

Copy the sample config.yaml file to the current directory::
   
   cp /root/config.yaml .

You'll want to configure this example for your own situation, but the example looks like this::

  common:
    orchestrator_common:
      attributes:
        deployment_mode: ha_full
        deployment_engine: simplepuppet
      task_uuid: deployment_task

Change the deployment node to ``ha_compact`` to tell Fuel to use the Compact architecture. ::

    openstack_common:
     internal_virtual_ip: 10.20.0.200
     public_virtual_ip: 192.168.56.100
     create_networks: "pp"
     fixed_range: 172.16.0.0/16
     floating_range: 192.168.56.0/24

Change the virtual IPs to match the target networks, and set the fixed and floating ranges. ::

     nv_physical_volumes:
      - /dev/sdb

Later, we'll set up a new partition for Cinder, so tell Cobbler to create it here. ::

   external_ip_info:
     public_net_router: 10.20.0.10
     ext_bridge: 10.20.0.1
     pool_start: 10.20.0.201
     pool_end: 10.20.0.254

Set the ``public_net_router`` to be the master node.  The ``ext_bridge`` is, in this case, the host machine. ::

   segment_range: 900:999
   use_syslog: false
   syslog_server: 127.0.0.1
   mirror_type: default
   quantum: true
   internal_interface: eth0
   public_interface: eth1
   private_interface: eth2

Earlier, we decided which interfaces to use for which networks; note that here.

   default_gateway: 10.20.0.10

Set the default gateway to the master node. ::

   nagios_master: fuel-controller-01.local
   loopback: loopback
   cinder: true
   cinder_on_computes: true
   swift: true

We've chosen to run Cinder and Swift, so you'll need to note that here, as well, as noting that we want to run Cinder on the compute nodes, as opposed to the controllers or a separate node. ::

   dns_nameservers:
   - 10.20.0.10
   - 8.8.8.8

The slave nodes should first look to the master node for DNS, so mark that as your first nameserver.

The next step is to define the nodes themselves.  To do that, you'll list each node once for each role that needs to be installed. ::

   nodes:
   - name: fuel-controller-01
     role: controller
     internal_address: 10.20.0.101
     public_address: 10.20.1.101
   - name: fuel-controller-02
     role: controller
     internal_address: 10.20.0.102
     public_address: 10.20.1.102
   - name: fuel-controller-01
     role: compute
     internal_address: 10.20.0.101
     public_address: 10.20.1.101
   - name: fuel-controller-02
     role: compute
     internal_address: 10.20.0.102
     public_address: 10.20.1.102
   - name: fuel-controller-01
     role: storage
     internal_address: 10.20.0.101
     public_address: 10.20.1.101
   - name: fuel-controller-02
     role: storage
     internal_address: 10.20.0.102
     public_address: 10.20.1.102
   - name: fuel-controller-01
     role: swift-proxy
     internal_address: 10.20.0.101
     public_address: 10.20.1.101
   - name: fuel-controller-02
     role: swift-proxy
     internal_address: 10.20.0.102
     public_address: 10.20.1.102
   - name: fuel-controller-01
     role: quantum
     internal_address: 10.20.0.101
     public_address: 10.20.1.101

Notice that each node is listed multiple times; this is because each node fulfills multiple roles. 

The ``cobbler_common`` section applies to all machines::

  cobbler_common:
    # for Centos
    # profile: "centos63_x86_64"
    # for Ubuntu
    profile: "ubuntu_1204_x86_64"

Fuel can install CentOS or Ubuntu on your servers, or you can add a profile of your own.

    netboot-enabled: "1"
    # for Ubuntu
    # ksmeta: "puppet_version=2.7.19-1puppetlabs2 \
    # for Centos
    name-servers: "10.20.0.10"
    name-servers-search: "your-domain-name.com"

Set the default nameserver to be fuel-pm, and change the domain name to your own domain name. ::

    ksmeta: "puppet_version=2.7.19-1puppetlabs2 \
      puppet_auto_setup=1 \
      puppet_master=fuel-pm.your-domain-name.com \

Change the fully-qualified domain name for the Puppet Master to reflect your own domain name.
 ::
      puppet_enable=0 \
      ntp_enable=1 \
      mco_auto_setup=1 \
      mco_pskey=un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi \
      mco_stomphost=10.20.0.10 \
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
        mac: "08:00:27:75:58:C2"
        static: "1"
        ip-address: "10.20.0.101"
        netmask: "255.255.255.0"
        dns-name: "fuel-controller-01.your-domain-name.com"
        management: "1"
      eth1:
        static: "0"
      eth2:
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

The only part of this section that you need to touch is the defintion of the eth0 interface; change the mac address to match the actual MAC address.  (You can retrieve this information by expanding "Advanced" for the network adapater in VirtualBox, or by executing ifconfig on the server itself.)  Also, make sure the ip-address is correct, and that the dns-name has your own domain name in it.

Repeat that step for any additional controllers::

  fuel-controller-02:
  # If you need create 'cinder-volumes' VG at install OS -- uncomment this line and  move it above in middle of ksmeta section.
  # At this line you need describe list of block devices, that must come in this group.
  # cinder_bd_for_vg=/dev/sdb,/dev/sdc \
    hostname: "fuel-controller-02"
    role: controller
    interfaces:
      eth0:
        mac: "08:00:27:C4:D8:CF"
        static: "1"
        ip-address: "10.20.0.102"
        netmask: "255.255.255.0"
        dns-name: "fuel-controller-02.your-domain-name"
        management: "1"
      eth1:
        static: "0"
      eth2:
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

  fuel-controller-03:
  # If you need create 'cinder-volumes' VG at install OS -- uncomment this line and  move it above in middle of ksmeta section.
  # At this line you need describe list of block devices, that must come in this group.
  # cinder_bd_for_vg=/dev/sdb,/dev/sdc \
    hostname: "fuel-controller-03"
    role: controller
    interfaces:
      eth0:
        mac: "08:00:27:C4:D8:CF"
        static: "1"
        ip-address: "10.20.0.103"
        netmask: "255.255.255.0"
        dns-name: "fuel-controller-03.your-domain-name"
        management: "1"
      eth1:
        static: "0"
      eth2:
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

  fuel-compute-01:
  # If you need create 'cinder-volumes' VG at install OS -- uncomment this line and  move it above in middle of ksmeta section.
  # At this line you need describe list of block devices, that must come in this group.
  # cinder_bd_for_vg=/dev/sdb,/dev/sdc \
    hostname: "fuel-compute-01"
    role: compute
    interfaces:
      eth0:
        mac: "08:00:27:C4:D8:CF"
        static: "1"
        ip-address: "10.20.0.201"
        netmask: "255.255.255.0"
        dns-name: "fuel-compute-01.your-domain-name"
        management: "1"
      eth1:
        static: "0"
      eth2:
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
  

This file has been customized for the example in the docs, but in general you will need to be certain that IP and gateway information -- in addition to the MAC addresses -- matches the decisions you made earlier in the process.




