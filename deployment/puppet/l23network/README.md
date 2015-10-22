L23network
==========
Puppet module for configuring network interfaces on 2nd and 3rd level (802.1q vlans, access ports, NIC-bondind, assign IP addresses, dhcp, and interfaces without IP addresses). 
Can work together with Open vSwitch or standart linux way.
At this moment support Centos 6.3+ (RHEL6) and Ubuntu 12.04 or above.

L23network module have a same behavior for both operation systems.

**WARNING!!!** This is a L23network v1.1, it contains some incompatibles with earlier versions. *Be carefully*.

## Usage

### Initializing 

Place this module at /etc/puppet/modules/l23network or another directory with your puppet modules.

Include L23network module and initialize it. It is recommended to do it on the early stage:

    #Network configuration
    stage {'netconfig':
      before  => Stage['main'],
    }
    class { 'l23network':
      use_ovs => true,
      use_lnx => true,
      stage   => 'netconfig'
    }

Initialization class 'l23network' has following incoming parameters and its default values:

    class { 'l23network':
      use_ovs                      => false,
      use_lnx                      => true,
      install_ovs                  => $use_ovs,
      install_brtool               => $use_lnx,
      install_ethtool              => $use_lnx,
      install_bondtool             => $use_lnx,
      install_vlantool             => $use_lnx,
      ovs_module_name              => undef,
      use_ovs_dkms_datapath_module => undef,
      ovs_datapath_package_name    => undef,
      ovs_common_package_name      => undef,
    }

For highly customized configurations you can redefine each of ones. For example, if you plan to use open vSwitch you should enable it:

    class {'l23network': 
      use_ovs=>true
    }


### L2 network features configuation

Current layout is:
* *bridges* -- A "Bridge" is a virtual ethernet L2 switch. You can plug ports into it.
* *ports* -- A Port is an interface you plug into the bridge. It may be virtual or native interface.

Then in your manifest you can either use it as a parameterized classes:

    l23network::l2::bridge{"br-mgmt": }
    l23network::l2::port{"eth0": bridge => "br-mgmt"}
    
    l23network::l2::bridge{"br-ex": provider => ovs }
    l23network::l2::port{"eth1": bridge => "br-ex" }
    l23network::l2::port{"ve0": bridge => "br-ex" }
    l23network::l2::port{"ve1": bridge => "br-ex" }


#### L2::Bridge

This resource implemented for configire of bridge.

    l23network::l2::bridge { 'br1':
      ensure          => present,
      stp             => true,  # or false
      vendor_specific => {
        .....
      },
      provider        => lnx,
    }

Non-obligatory fields:

* *stp* -- enable/disable STP for bridge
* *bpdu_forward* -- enable/disable BPDU forward on bridge
* *bridge_id* -- bridge_id for STP protocol.
* *vendor_specific* -- vendor_specific hash (see below)
* *delay_while_up* -- delay, in seconds, which will happens each time while node will boot after interface up.

#### L2::Port

Resource for configuring port L2 options. Only L2 options. For configuring
L3 options -- use *L23network::l3::ifconfig* resource

    l23network::l2::port { 'eth1':
      mtu     => 9000,   # MTU value, unchanged if absent.
      onboot  => true,   # whether port has UP state after setup or node boot
      ethtool => {
        .....
      },
      vendor_specific => {
        .....
      },
      provider => lnx
    }

    l23network::l2::port { 'eth1.101':
      ensure    => present,
      bridge    => 'br1',  # port can be a member of bridge. 
                           # If no value given this property was unchanged, 
                           # if given 'absent' port will be excluded from any
                           # bridges.
      onboot    => true,
      delay_while_up => 10
      provider  => lnx
    }

Alternative VLAN definition (not recommended for 'lnx' provider)

    l23network::l2::port { 'vlan77':
      vlan_id   => 77,
      vlan_dev  => eth1,
      provider  => lnx
    }

#### L2::Bond

It's a special type of port. Designed for bonding two or more interfaces.
Detail description of bonding feature you can read here:
https://www.kernel.org/doc/Documentation/networking/bonding.txt
If you plan use LACP -- we highly recommend do not use OVS.
Also we don't recommend insert native linux bonds to OVS bridges. This case works, but leads many heavy diagnostic surprises.

    l23network::l2::bond { 'bond0':
      interfaces      => ['eth1', 'eth2'],
      bridge          => 'br0',  # obligatory only for OVS provider
      mtu             => 9000,
      onboot          => true,
      bond_properties => {  # bond configuration properties (see bonding.txt)
        mode             => '803.1ad',
        lacp_rate        => 'slow',
        xmit_hash_policy => 'encap3+4'
      },
      interface_properties => {  # config properties for included ifaces
        ethtool => {
          .....
        },
      },
      vendor_specific => {
        .....
      },
      delay_while_up => 45
      provider => lnx,
    }

Bond **mode** and **xmit_hash_policy** configuration has some differences for
*lnx* and *ovs* providers:

For *lnx* provider **mode** can be:

* balance-rr  *(default)*
* active-backup
* balance-xor
* broadcast
* 802.3ad
* balance-tlb
* balance-alb

For 802.3ad (LACP), balance-xor, balance-tlb and balance-alb cases should be
defined **xmit_hash_policy** as one of:

* layer2  *(default)*
* layer2+3
* layer3+4
* encap2+3
* encap3+4

For *ovs* provider **mode** can be:

* active-backup
* balance-slb  *(default)*
* balance-tcp

Field **xmit_hash_policy** shouldn't use for any mode.
For *balance-tcp* mode **lacp** bond-property should be set
to 'active' or 'passive' value.

While bond will created also will created ports, included to the bond. This
ports will be created as slave ports for this bond with properties, listed in
**interface_properties** field. If you want more flexibility, you can create
this ports by *l23network::l2::port* resource and shouldn't define
**interface_properties** field.

**MTU** field, setted for bond interface will be passed to interfaces, included
to the bond automatically.

I recommend use **delay_while_up** property, while configure LACP bonds, because such bonds may take some time for settle.

For some providers (ex: ovs) **bridge** field is obligatory.

#### L2::Patch

It's a patchcord for connecting two bridges. Architecture limitation: two
bridges may be connected only by one patchcord. Name for patchcord interfaces
calculated automatically and can't changed in configuration.

OVS provider can connect OVS-to-OVS and OVS-to-LNX bridges. If you connect
OVS-to-LNX bridges, you SHOULD put OVS bridge first in order.

    l23network::l2::patch { 'patch__br0--br1':
      bridges => ['br0','br1'],
      vendor_specific => {
        .....
      },
    }

**Naming conviency**

Each low-level puppet patchcord resource *l2_patch* has his name in
'bridge__%bridge1%--%bridge2%' format, and bridges provided
in alphabetical order for all providers. This resource also contain 'bridges'
property.  It's a array of two bridge names.
Order of names depends of provider implementation.
For example, 'ovs' provider bridge names listed in alphabetical order for
OVS-to-OVS connectivity, and ovs-bridge always first for OVS-to-LNX bridges
connectivity.

Each *L2_patch* instance contains read-only 'jacks' property. It's a array
of two names of jacks, 'inserted' to each bridge. This property has the same
ordering style, that a 'bridges' property for this provider.

If patchcord connect two bridges different nature, the 'cross' flag will be
setting to 'true'.

#### Ethtool hash and offloading settings

You can manage offloading and another options, controlled by ethtool utility,
for any resources, that has *ethtool* hash as one of incoming properties.
*Ethtool* field look like hash of hashes. Keys of the external hash -- are a
section names from ethtool manual. Ones maps to an internal hashes. Internal
hashes -- is a option to value mappings. Option names corresponds to ethtool
output option naming. For example, you can see list of offloading options by
executing 'ethtool -k eth0'.
Ethtool options are pre-defined and stateful.
All implemented sections and options you can see bellow:

    ethtool => {
      offload => {
          rx-checksumming              => true or false,
          tx-checksumming              => true or false,
          scatter-gather               => true or false,
          tcp-segmentation-offload     => true or false,
          udp-fragmentation-offload    => true or false,
          generic-segmentation-offload => true or false,
          generic-receive-offload      => true or false,
          large-receive-offload        => true or false,
          rx-vlan-offload              => true or false,
          tx-vlan-offload              => true or false,
          ntuple-filters               => true or false,
          receive-hashing              => true or false,
          rx-fcs                       => true or false,
          rx-all                       => true or false,
          highdma                      => true or false,
          rx-vlan-filter               => true or false,
          fcoe-mtu                     => true or false,
          l2-fwd-offload               => true or false,
          loopback                     => true or false,
          tx-nocache-copy              => true or false,
          tx-gso-robust                => true or false,
          tx-fcoe-segmentation         => true or false,
          tx-gre-segmentation          => true or false,
          tx-ipip-segmentation         => true or false,
          tx-sit-segmentation          => true or false,
          tx-udp_tnl-segmentation      => true or false,
          tx-mpls-segmentation         => true or false,
          tx-vlan-stag-hw-insert       => true or false,
          rx-vlan-stag-hw-parse        => true or false,
          rx-vlan-stag-filter          => true or false,
      },
      #settings => {
      #   duplex => 'half',
      #   mdix   => off
      #}
    }


### L3 network configuration

#### L3::Ifconfig

Resource for configuring IP addresses on interface. Only L3 options.
For configuring L2 options -- use corresponded L2 resource.

    l23network::l3::ifconfig { 'eth1.101':
      ensure           => present,
      ipaddr           => ['192.168.10.3/24', '10.20.30.40/25'],
      gateway          => '192.168.10.1',
      gateway_metric   => 10,  # different Ifconfig resources should not has
                               # gateways with same metrics
      vendor_specific => {
        .....
      },
    }

**DHCP or address-less interfaces**

    l23network::l3::ifconfig {"eth2": ipaddr=>'dhcp'}
    l23network::l3::ifconfig {"eth3": ipaddr=>'none'}

Option *ipaddr* can contains array of IP addresses (even setup one ipaddr), 'dhcp', or 'none' string. 

CIDR-notated form of IP address is required. 

**Default gateway**

    l23network::l3::ifconfig {"eth1":
      ipaddr         => ['192.168.2.5/24'],
      gateway        => '192.168.2.1',
      gateway_metric => 10,
    }

if *gateway_metric* omited, gateway will be setup without metric definition.



## Network Scheme

Network scheme is a hierarchical-based manner for define network topology for host. In following examples I use yaml format for represent it. 
Main idea:
  * when we got undeployed server we have some number of NICs. NICs, managed by puppet should be listed in *interfaces* section. It is giveg.
  * The result of our network configuration process is a some network topology on the host and some interfaces with assignet IP addresses (or without IPs). It's a *endpoints*. 
  * Interfaces become endpoints by successive *transformations*. I try explain how it works in the following document: [Transformations. How they work.](https://docs.google.com/document/d/12RvBjOYO83_yqeiAgxttrRaa90-8un80aEO8OzDlQ9Y)

Example of typical network scheme:

    ---
    network_scheme:
      version: 1.1
      provider: lnx
      interfaces:
        eth1:
          mtu: 7777
        eth2:
          mtu: 9000
      transformations:
        - action: add-br
          name: br1
        - action: add-port
          name: eth1
          bridge: br1
        - action: add-br
          name: br-mgmt
        - action: add-port
          name: eth1.101
          bridge: br-mgmt
        - action: add-br
          name: br-ex
        - action: add-port
          name: eth1.102
          bridge: br-ex
        - action: add-br
          name: br-storage
        - action: add-port
          name: eth1.103
          bridge: br-storage
        - action: add-br
          name: br-prv
          provider: ovs
        - action: add-port
          name: eth2
          bridge: br-prv
          provider: ovs
      endpoints:
        br-mgmt:
          IP:
            - 192.168.101.3/24
          gateway: 192.168.101.1
          gateway-metric: 100
          routes:
            - net: 192.168.210.0/24
              via: 192.168.101.1
            - net: 192.168.211.0/24
              via: 192.168.101.1
            - net: 192.168.212.0/24
              via: 192.168.101.1
        br-ex:
          gateway: 192.168.102.1
          IP:
            - 192.168.102.3/24
        br-storage:
          IP:
            - 192.168.103.3/24
        br-prv:
          IP: none
      roles:
        management: br-mgmt
        ceph: br-mgmt
        private: br-prv
        fw-admin: br1
        ex: br-ex
        floating: br-ex
        storage: br-storage


Example of typical network scheme with bonds and disabling offloads:

    ---
    network_scheme:
      version: "1.1"
      provider: lnx
      interfaces:
        eth1:
          mtu: 9000
        eth2:
        eth3:
      transformations:
        - action: add-br
          name: br1
        - action: add-port
          bridge: br1
          name: eth1
          ethtool:
            offload:
              tcp-segmentation-offload: off
              udp-fragmentation-offload: off
              generic-segmentation-offload: off
              generic-receive-offload: off
              large-receive-offload: off
        - action: add-br
          name: br2
        - action: add-bond
          name: bond23
          bridge: br2
          interfaces:
            - eth2
            - eth3
          mtu: 9000
          interface_properties:
            ethtool:
              offload:
                tcp-segmentation-offload: off
                udp-fragmentation-offload: off
          bond_properties:
            mode: balance-rr
            xmit_hash_policy: encap3+4
            updelay: 10
            downdelay: 40
            use_carrier: 0
        - action: add-br
          name: br-mgmt
        - action: add-port
          name: bond23.101
          bridge: br-mgmt
        - action: add-br
          name: br-ex
        - action: add-port
          name: bond23.102
          bridge: br-ex
        - action: add-br
          name: br-storage
        - action: add-port
          name: bond23.103
          bridge: br-storage
      endpoints:
        br-mgmt:
          IP:
            - 192.168.101.3/24
          gateway: 192.168.101.1
          gateway-metric: 100
        br-ex:
          gateway: 192.168.102.1
          IP:
            - 192.168.102.3/24
        br-storage:
          IP:
            - 192.168.103.3/24
      roles:
        fw-admin: br1
        ex: br-ex
        management: br-mgmt
        storage: br-storage


## Vendor_specific hash

**Vendor_specific** field - is a hash, empty by default,
required only for plug-ins. It allows plugin developers not to change custom
type code for adding non-standart parameters. Due to inheriting and extending
puppet type (not the provider one), is a non-trivial task. Plugin developers
may pass any data structures by this hash and its subhashes. All data from
this hash pass to the provider transparently.


## Debugging

For debug purpose you can use following puppet calls for get prefetchable
properties for existing resources. Please note, that bridges and bonds in linux
are a port too, and present in l2_port output with corresponded flags
(if_type).

    # puppet resource -vd --trace l23_stored_config
    # puppet resource -vd --trace l2_port
    # puppet resource -vd --trace l2_bridge
    # puppet resource -vd --trace l2_bond
    # puppet resource -vd --trace l3_ifconfig
    # puppet resource -vd --trace l3_route

This commands may be fail before 1st configuration networking by L23network
because some kernel modules may wasn't loaded or some command-line tools
wasn't installed.


## Internals

Each L23network resource has interface trought puppet 'define' resource.
This define may conains some non difficult logic, define provider for low-level resources and call two low level resources:
  * *l23_stored_config* -- for modifying OS config files 
  * low level resource for configuring it in runtime (e.x: *l2_bridge*)

### L23_stored_config custom type

This resource is implemented to manage interface config files. Each possible
parameter should be described in resource type.

This resource allows to forget about ERB templates, because in some cases
(i.e.  bridge + port with same name + ip address for this port) we should
modify config file content three times.

    l23_stored_config { 'br1':
      onboot   => true,
      method   => manual,
      mtu      => 1500,
      ethtool => {
        .....
      },
      provider => lnx_ubuntu
    }

Place of config files location defined inside provider for corresponded
operation system and provider. Provider name for l23_stored_config depends from operation system (may be with version) and network provider (native linux, ovs, etc...)

## References

  * [Transformations. How they work.](https://docs.google.com/document/d/12RvBjOYO83_yqeiAgxttrRaa90-8un80aEO8OzDlQ9Y)

---
When I started working on this module I was inspired by https://github.com/ekarlso/puppet-vswitch. Endre, big thanks...
