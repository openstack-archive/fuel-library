L23network
==========

This puppet module is for configuring L2 and L3 network interfaces (e.g 802.1q
vlans, access ports, NIC-bonding, assigning IP addresses, DHCP, and interfaces
without IP addresses).

It works with standard Linux interfaces as well as with Open vSwitch
interfaces. At the moment, it supports CentOS/RHEL 6.3+ and Ubuntu 12.04+. The
module should have the same behavior across both operating systems.

**WARNING!!!** This is l23network v1.1, which contains some incompatibilities
with earlier versions. *Be careful*.


## Usage



### Initialization

Place this module at /etc/puppet/modules/l23network or in the directory where
your puppet modules are stored.

Include the l23network module and initialize it. It is recommended to do this
during an early puppet stage (before the main stage). E.g.

    # Network configuration
    stage { 'netconfig':
      before => Stage['main'],
    }
    class { 'l23network':
      use_ovs => true,
      use_lnx => true,
      stage   => 'netconfig'
    }

The 'l23network' class has the following parameters and default values:

    class { 'l23network':
      use_ovs                      => false,
      use_lnx                      => true,
      install_ovs                  => $use_ovs,
      install_brtool               => $use_lnx,
      modprobe_bridge              => $use_lnx,
      install_bondtool             => $use_lnx,
      modprobe_bonding             => $use_lnx,
      install_vlantool             => $use_lnx,
      modprobe_8021q               => $use_lnx,
      install_ethtool              => $use_lnx,
      ovs_module_name              => undef,
      use_ovs_dkms_datapath_module => undef,
      ovs_datapath_package_name    => undef,
      ovs_common_package_name      => undef,
    }

If you plan to use Open vSwitch you can enable it as follows:

    class { 'l23network':
      use_ovs => true,
    }



### L2 Network Configuration

The following L2 concepts are used:

* *bridge* - a virtual ethernet L2 switch. You can plug ports into
  a bridge.
* *port* - an interface that you plug into the bridge. A port may be a virtual
  or a physical interface.

These can be used as parameterized classes:

    l23network::l2::bridge { 'br-mgmt': }
    l23network::l2::port { 'eth0': bridge => 'br-mgmt' }

    l23network::l2::bridge { 'br-ex': provider => ovs }
    l23network::l2::port { 'eth1': bridge => 'br-ex' }
    l23network::l2::port { 've0': bridge => 'br-ex' }
    l23network::l2::port { 've1': bridge => 'br-ex' }

The following sections describe their usage in more detail.


#### L2::bridge

This resource is for configuring bridges:

    l23network::l2::bridge { 'br1':
      ensure          => present,
      stp             => true,  # or false
      vendor_specific => {
        .....
      },
      provider        => lnx,
    }

Optional parameters:

* *stp* - enable/disable STP for the bridge
* *bpdu_forward* - enable/disable BPDU forwarding on the bridge
* *bridge_id* - bridge_id for the STP protocol
* *vendor_specific* - vendor_specific hash (see below)
* *delay_while_up* - delay, in seconds, after the interface comes up, which
  happens every time the nodes boots


#### L2::port

This resource is for configuring ports with L2 options. To configure L3
options, use the *l23network::l3::ifconfig* resource.

    l23network::l2::port { 'eth1':
      mtu     => 9000,  # MTU value, unchanged if absent
      onboot  => true,  # Whether port has UP state after setup or node boot
      ethtool => {
        .....
      },
      vendor_specific => {
        .....
      },
      provider => lnx,
    }

    l23network::l2::port { 'eth1.101':
      ensure         => present,
      bridge         => 'br1',  # port can be a member of a bridge
                                # If no value is given this property remains
                                # unchanged. If 'absent' is given the port will
                                # be excluded from any bridges
      onboot         => true,
      delay_while_up => 10,
      provider       => lnx,
    }

Alternative VLAN definition (not recommended for 'lnx' provider)

    l23network::l2::port { 'vlan77':
      vlan_id   => 77,
      vlan_dev  => eth1,
      provider  => lnx,
    }


#### L2::bond

This is a special type of port for bonding two or more interfaces. A detailed
description of bonding is available
[here](https://www.kernel.org/doc/Documentation/networking/bonding.txt).
If you plan to use LACP, we highly recommend not using OVS. We also recommend
not inserting native linux bonds into OVS bridges. This case works, but leads
to many complications when troubleshooting.

    l23network::l2::bond { 'bond0':
      interfaces      => ['eth1', 'eth2'],
      bridge          => 'br0',  # only required for OVS provider
      mtu             => 9000,
      onboot          => true,
      bond_properties => {  # bond configuration properties (see bonding.txt)
        mode             => '803.1ad',
        lacp_rate        => 'slow',
        xmit_hash_policy => 'encap3+4'
      },
      interface_properties => {  # config properties for included interfaces
        ethtool => {
          .....
        },
      },
      vendor_specific => {
        .....
      },
      delay_while_up => 45,
      provider => lnx,
    }

**mode** and **xmit_hash_policy** parameters have some differences depending
on whether the provider is *lnx* or *ovs*:

For *lnx* provider **mode** can be:

* balance-rr  *(default)*
* active-backup
* balance-xor
* broadcast
* 802.3ad
* balance-tlb
* balance-alb

For 802.3ad (LACP) with balance-xor, balance-tlb or balance-alb
 **xmit_hash_policy** should be defined as one of:

* layer2  *(default)*
* layer2+3
* layer3+4
* encap2+3
* encap3+4

For *ovs* provider **mode** can be:

* active-backup
* balance-slb  *(default)*
* balance-tcp

If **mode** is balance-tcp, **lacp** should be set to 'active' or 'passive'.

The **xmit_hash_policy** parameter is not used for *ovs* bonds at all.

When the bond is created, it will also create the ports for the bond slaves.
These ports will be created with the properties specified by the
**interface_properties** parameter. For further flexibility, these ports can be
created using the *l23network::l2::port* resource. In this case, do not use the
**interface_properties** parameter.

When the **mtu** parameter is set on a bonded interface, the MTU will also be
assigned to slave interfaces automatically.

It is recommended to use the **delay_while_up** parameter when configuring LACP
bonds, because such bonds may take some time to settle.

For some providers (e.g. *ovs*), the **bridge** parameter is obligatory.


#### L2::patch

This resource is a patchcord for connecting two bridges. One architecture
limitation is that two bridges can only be connected by one patchcord. The name
for the patchcord interfaces is calculated automatically and cannot be changed.

The *ovs* provider can connect OVS-to-OVS, OVS-to-LNX and LNX-to-LNX bridges.
You should always create the bridges before using this resource.

    l23network::l2::patch { 'patch__br0--br1':
      bridges         => ['br0','br1'],
      vendor_specific => {
        .....
      },
    }

##### Naming Conventions

Each low-level patchcord resource l2::patch has its name in the following
format: 'bridge__%bridge1%--%bridge2%', with the bridges in alphabetical order
for all providers.

This resource also contains a 'bridges' property which is an array of the two
bridge names. The order of the names depends on the provider implementation.
For example, the *ovs* provider bridge names are listed in alphabetical order
for OVS-to-OVS connections, and ovs-bridge is always listed first for
OVS-to-LNX bridges.

Each L2::patch instance contains a read-only 'jacks' property, which is an
array of two names of jacks, 'inserted' into each bridge. This property has the
same ordering style as the 'bridges' property for each provider.

If a patchcord connects two different types of bridges, the 'cross' property will
be set to 'true'.


#### Ethtool hash and offloading settings

To manage offloading and other ethtool options for any resources, it is
possible to use the *ethtool* parameter. This is like a hash of hashes. Keys of
the external hash map to section names from the ethtool manual. Each section
name maps to an internal hash. Internal hashes are option to value mappings,
where option names correspond to ethtool output option naming. For example, you
can see list of offloading options by executing 'ethtool -k eth0'.

Ethtool options are pre-defined and stateful.

All implemented sections and options are listed below.

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
      settings => {
         duplex => 'half',
         mdix   => off
      }
    }



### L3 Network Configuration


#### L3::ifconfig

This resource is for configuring IP addresses on an interface. Only L3 options.
For configuring L2 options, use the L2 resources.

    l23network::l3::ifconfig { 'eth1.101':
      ensure           => present,
      ipaddr           => ['192.168.10.3/24', '10.20.30.40/25'],
      gateway          => '192.168.10.1',
      gateway_metric   => 10,  # different ifconfig resources should not have
                               # gateways with same metric
      vendor_specific  => {
        .....
      },
    }

The option *ipaddr* may contain an array of IP addresses (even to configure a
single IP address), 'dhcp', or 'none'. CIDR-notation is required for the IP
address.

DHCP or address-less interfaces are configured as follows:

    l23network::l3::ifconfig { 'eth2': ipaddr => 'dhcp' }
    l23network::l3::ifconfig { 'eth3': ipaddr => 'none' }

The default gateway can be configured as follows:

    l23network::l3::ifconfig { 'eth1':
      ipaddr         => ['192.168.2.5/24'],
      gateway        => '192.168.2.1',
      gateway_metric => 10,
    }

If *gateway_metric* is omitted, the gateway will be configured without a
metric.



## Network Schemes

*network_scheme* is a hierarchical-based scheme to define a network topology
for a host. In the following examples the yaml format is used.

The main idea is as follows:
  * When we have an undeployed server we have a number of NICs. NICs, managed
    by puppet should be listed in the *interfaces* section.
  * The result of our network configuration process is a network topology on
    the host with interfaces that are assigned IP addresses (or not). These
    are the *endpoints*.
  * Interfaces become endpoints by successive *transformations*.
    Transformations are explained in the following document:
    [Transformations. How they work.](https://docs.google.com/document/d/12RvBjOYO83_yqeiAgxttrRaa90-8un80aEO8OzDlQ9Y)


Example of a typical network scheme:

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


Example of typical network scheme with bonding and offloads disabled:

    ---
    network_scheme:
      version: 1.1
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



## Vendor-specific Parameters

The **vendor_specific** parameter is a hash, empty by default, required only
for plug-ins. It allows plugin developers to use custom code for adding
non-standard parameters. As a result of inheriting and extending the
puppet type (not the provider), this a non-trivial task. Plugin developers
may pass any data structures using this hash and its subhashes. All data from
this hash is passed to the provider transparently.



## Debugging

For debug purposes you can use following puppet calls to get prefetchable
properties for existing resources. Please note that bridges and bonds in linux
are ports too, and are present in the l2_port output with the corresponding
flags (if_type).

    # puppet resource -vd --trace l23_stored_config
    # puppet resource -vd --trace l2_port
    # puppet resource -vd --trace l2_bridge
    # puppet resource -vd --trace l2_bond
    # puppet resource -vd --trace l3_ifconfig
    # puppet resource -vd --trace l3_route

These commands may fail before the initial configuration run by L23network
because some kernel modules are not loaded or some command-line tools are not
installed.



## Internals

Each L23network resource has an interface through the puppet 'define' resource.
These defines contain some simple logic, including the define provider for
low-level resources and a call to two low-level resources:
  * *l23_stored_config* - for modifying OS config files
  * low-level resource for live-configuring the resource (e.g. *l2_bridge*)


### L23_stored_config Custom Type

This resource manages the interface configuration files directly. Each
possible parameter should be described in the resource type.

This resource allows us to avoid using ERB templates, because in some cases
(e.g. bridge and port with the same name and IP address) we need to modify the
same config file content three times.

    l23_stored_config { 'br1':
      onboot   => true,
      method   => manual,
      mtu      => 1500,
      ethtool  => {
        .....
      },
      provider => lnx_ubuntu,
    }

The location of the configuration files is defined inside the provider for the
corresponding operating system and provider. The provider name for
*l23_stored_config* also depends on the operating system, the operating system
version, and the specific network provider (native linux, ovs, etc...)



## Supported operating systems

  * CentOS 6 and 7
  * RedHat 7
  * OracleLinux 7
  * Ubuntu



## References

  * [Transformations. How they work.](https://docs.google.com/document/d/12RvBjOYO83_yqeiAgxttrRaa90-8un80aEO8OzDlQ9Y)

---
When I started working on this module I was inspired by https://github.com/ekarlso/puppet-vswitch. Endre, big thanks...
