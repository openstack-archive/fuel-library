L23network
==========
Puppet module for configuring network interfaces, 802.1q vlans and bondings on 2 and 3 level. 

Can work together with open vSwitch or standart linux way.  At this moment support CentOS 6.3 (RHEL6) and Ubuntu 12.04 or above.


Usage
-----
Place this module at /etc/puppet/modules/l23network or another directory with your puppet modules.

Include L23network module and initialize it. It is recommended to do it on the early stage:

    #Network configuration
    stage {'netconfig':
      before  => Stage['main'],
    }
    class {'l23network': stage=> 'netconfig'}

If you do not plan to use open vSwitch you can disable it:

    class {'l23network': use_ovs=>false, stage=> 'netconfig'}


L2 network configuation
-----------------------

Current layout is:
* *bridges* -- A "Bridge" is a virtual ethernet L2 switch. You can plug ports into it.
* *ports* -- A Port is an interface you plug into the bridge (switch). It's virtual.
* *interface* -- A physical implementation of port.

Then in your manifest you can either use it as a parameterized classes:

    class {"l23network": }
    
    l23network::l2::bridge{"br-mgmt": }
    l23network::l2::port{"eth0": bridge => "br-mgmt"}
    l23network::l2::port{"mmm0": bridge => "br-mgmt"}
    l23network::l2::port{"mmm1": bridge => "br-mgmt"}
    
    l23network::l2::bridge{"br-ex": }
    l23network::l2::port{"eth0": bridge => "br-ex"}
    l23network::l2::port{"eth1": bridge => "br-ex", ifname_order_prefix='ovs'}
    l23network::l2::port{"eee0": bridge => "br-ex", skip_existing => true}
    l23network::l2::port{"eee1": bridge => "br-ex", type=>'internal'}

You can define a type for the port. Port types are:
'system', 'internal', 'tap', 'gre', 'ipsec_gre', 'capwap', 'patch', 'null'.
If you do not define type for port (or define '') then ovs-vsctl will work by default
(see http://openvswitch.org/cgi-bin/ovsman.cgi?page=utilities%2Fovs-vsctl.8).

You can use skip_existing option if you do not want to interrupt the configuration during adding of existing port or bridge.

    L3 network configuration
    -----------------------
    
    l23network::l3::ifconfig {"some_name0": interface=>'eth0', ipaddr=>'192.168.0.1', netmask=>'255.255.255.0'}
    l23network::l3::ifconfig {"some_name1": interface=>'br-ex', ipaddr=>'192.168.10.1', netmask=>'255.255.255.0', ifname_order_prefix='ovs'}
    l23network::l3::ifconfig {"some_name2": interface=>'aaa0', ipaddr=>'192.168.10.1', netmask=>'255.255.255.0', ifname_order_prefix='zzz'}
    
    Option 'ipaddr' can contain IP address, 'dhcp', or 'none' (for interface with no IP address).

When CentOS or Ubuntu starts they initialize and configure network interfaces in alphabetical order. 
In example above we change the order of configuration process by ifname_order_prefix keyword. The order will be:

    ifcfg-eth0
    ifcfg-ovs-br-ex
    ifcfg-zzz-aaa0

And the OS will configure interfaces br-ex and aaa0 after eth0

Bonding
-------
### Using standart linux ifenslave bonding
For bonding of two interfaces you need to:
* Configure the bonded interfaces as 'none' (with no IP address)
* Specify that interfaces depend on bond_master interface
* Assign IP address to the bond-master interface
* Specify bond-specific properties for bond_master interface (if you are not happy with defaults)

For example (defaults included):   

    l23network::l3::ifconfig {'eth1': ipaddr=>'none', bond_master=>'bond0'} ->
    l23network::l3::ifconfig {'eth2': ipaddr=>'none', bond_master=>'bond0'} ->
    l23network::l3::ifconfig {'bond0':
        ipaddr          => '192.168.232.1',
        netmask         => '255.255.255.0',
        bond_mode       => 0,
        bond_miimon     => 100,
        bond_lacp_rate  => 1,
    }


More information about bonding of network interfaces you can find in manuals for you operation system:
* https://help.ubuntu.com/community/UbuntuBonding
* http://wiki.centos.org/TipsAndTricks/BondingInterfaces

### Using open vSwitch
In open vSwitch for bonding of two network interfaces you need to add a special resource "bond" to bridge.
In this example we add "eth1" and "eth2" interfaces to bridge "bridge0":

    l23network::l2::bridge{'bridge0': } ->
    l23network::l2::bond{'bond1':
        bridge     => 'bridge0',
        ports      => ['eth1', 'eth2'],
        properties => [
           'lacp=active',
           'other_config:lacp-time=fast'
        ],
    }

Open vSwitch provides a lot of parameter for different configurations. 
We can specify them in "properties" option as list of parameter=value 
(or parameter:key=value) strings.
You can find more parameters in [open vSwitch documentation page](http://openvswitch.org/support/).

802.1q vlan access ports
------------------------
### Using standart linux way
We can use tagged vlans over ordinary network interfaces and over bonds. 
L23networks module supports two types of vlan interface namings:
* *vlanXXX* -- 802.1q tag XXX from the vlan interface name. You must specify the
parent interface name in the **vlandev** parameter.
* *eth0.XXX* -- 802.1q tag XXX and parent interface name from the vlan interface name

If you are using 802.1q vlans over bonds it is recommended to use the first one.

In this example we can see both types:

    l23network::l3::ifconfig {'vlan6':
        ipaddr  => '192.168.6.1',
        netmask => '255.255.255.0',
        vlandev => 'bond0',
    } 
    l23network::l3::ifconfig {'vlan5': 
        ipaddr  => 'none',
        vlandev => 'bond0',
    } 
    L23network:L3:Ifconfig['bond0'] -> L23network:L3:Ifconfig['vlan6'] -> L23network:L3:Ifconfig['vlan5']

    l23network::l3::ifconfig {'eth0':
        ipaddr  => '192.168.0.5',
        netmask => '255.255.255.0',
        gateway => '192.168.0.1',
    } ->
    l23network::l3::ifconfig {'eth0.101':
        ipaddr  => '192.168.101.1',
        netmask => '255.255.255.0',
    } ->
    l23network::l3::ifconfig {'eth0.102':
        ipaddr  => 'none',    
    } 

### Using open vSwitch
In the open vSwitch all internal traffic is virtually tagged.
To create a 802.1q tagged access port you need to specify a vlan tag when adding a port to the bridge. 
In example above we create two ports with tags 10 and 20:

    l23network::l2::bridge{'bridge0': } ->
    l23network::l2::port{'vl10':
      bridge  => 'bridge0',
      type    => 'internal',
      port_properties => ['tag=10'],
    } ->
    l23network::l2::port{'vl20':
      bridge  => 'bridge0',
      type    => 'internal',
      port_properties => ['tag=20'],
    }
    
You can get more details about vlans in open vSwitch at [open vSwitch documentation page](http://openvswitch.org/support/config-cookbooks/vlan-configuration-cookbook/).

**IMPORTANT:** You can't use vlan interface names like vlanXXX if you don't want double-tagging of you network traffic.

---
When I started working on this module I was inspired by https://github.com/ekarlso/puppet-vswitch. Endre, big thanks...
