L23network
==========
Puppet module for configuring network interfaces, 802.1q vlans, bonds on 2 and 3 level. Can work together with open vSwitch or standart linux way.  At this moment support Centos 6.3 (RHEL6) and Ubuntu 12.04 or above.


Usage
-----
Place this module at /etc/puppet/modules/l23network or to another directory, contains your puppet modules.

Include L23network module and initialize it. I recommend do it in early stage:

    #Network configuration
    stage {'netconfig':
      before  => Stage['main'],
    }
    class {'l23network': stage=> 'netconfig'}

If You not planned using open vSwitch -- you can disable it:

    class {'l23network': use_ovs=>false, stage=> 'netconfig'}


L2 network configuation
-----------------------

Current layout is:
* *bridges* -- A "Bridge" is a virtual ethernet L2 switch. You can plug ports into it.
* *ports* -- A Port is a interface you plug into the bridge (switch). It's a virtual.
* *interface* -- A physical implementation of port.

Then in your manifest you can either use the things as parameterized classes:

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

You can define type for the port. Port type can be
'system', 'internal', 'tap', 'gre', 'ipsec_gre', 'capwap', 'patch', 'null'.
If you not define type for port (or define '') -- ovs-vsctl will have default behavior 
(see http://openvswitch.org/cgi-bin/ovsman.cgi?page=utilities%2Fovs-vsctl.8).

You can use skip_existing option if you not want interrupt configuration during adding existing port or bridge.

    L3 network configuation
    -----------------------
    
    l23network::l3::ifconfig {"some_name0": interface=>'eth0', ipaddr=>'192.168.0.1', netmask=>'255.255.255.0'}
    l23network::l3::ifconfig {"some_name1": interface=>'br-ex', ipaddr=>'192.168.10.1', netmask=>'255.255.255.0', ifname_order_prefix='ovs'}
    l23network::l3::ifconfig {"some_name2": interface=>'aaa0', ipaddr=>'192.168.10.1', netmask=>'255.255.255.0', ifname_order_prefix='zzz'}
    
    Option 'ipaddr' can contains IP address, 'dhcp', or 'none' for up empty unaddressed interface.

Centos and Ubuntu at startup started and configure network interfaces in alphabetical order interface configuration file names. In example above we change configuration process order by ifname_order_prefix keyword. We will have this order:

    ifcfg-eth0
    ifcfg-ovs-br-ex
    ifcfg-zzz-aaa0

And OS will configure interfaces br-ex and aaa0 after eth0

Bonding
-------
### Using standart linux ifenslave bond
For bonding two interfaces you need:
* Specify this interfaces as interfaces without IP addresses
* Specify that interfaces depends from master-bond-interface
* Assign IP address to the master-bond-interface.
* Specify bond-specific properties for master-bond-interface (if defaults not happy for you)

for example (defaults included):   

    l23network::l3::ifconfig {'eth1': ipaddr=>'none', bond_master=>'bond0'} ->
    l23network::l3::ifconfig {'eth2': ipaddr=>'none', bond_master=>'bond0'} ->
    l23network::l3::ifconfig {'bond0':
        ipaddr          => '192.168.232.1',
        netmask         => '255.255.255.0',
        bond_mode       => 0,
        bond_miimon     => 100,
        bond_lacp_rate  => 1,
    }


more information about bonding network interfaces you can get in manuals for you operation system:
* https://help.ubuntu.com/community/UbuntuBonding
* http://wiki.centos.org/TipsAndTricks/BondingInterfaces

### Using open vSwitch
In open vSwitch for bonding two network interfaces you need add special resource "bond" to bridge. 
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

Open vSwitch provides lot of parameter for different configurations. 
We can specify them in "properties" option as list of parameter=value 
(or parameter:key=value) strings.
The most of them you can see in [open vSwitch documentation page](http://openvswitch.org/support/).

802.1q vlan access ports
------------------------
### Using standart linux way
We can use tagged vlans over ordinary network interfaces and over bonds. 
L23networks support two variants of naming vlan interfaces:
* *vlanXXX* -- 802.1q tag gives from the vlan interface name, but you need specify 
parent intarface name in the **vlandev** parameter.
* *eth0.101* -- 802.1q tag and parent interface name gives from the vlan interface name

If you need using 802.1q vlans over bonds -- you can use only first variant.

In this example we can see both variants:

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
In the open vSwitch all internal traffic are virtually tagged.
For creating 802.1q tagged access port you need specify vlan tag when adding port to bridge. 
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
    
Information about vlans in open vSwitch you can get in [open vSwitch documentation page](http://openvswitch.org/support/config-cookbooks/vlan-configuration-cookbook/).

**IMPORTANT:** You can't use vlan interface names like vlanXXX if you not want double-tagging you network traffic.

---
When I began write this module, I seen to https://github.com/ekarlso/puppet-vswitch. Elcarso, big thanks...
