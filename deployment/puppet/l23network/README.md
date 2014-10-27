L23network
==========
Puppet module for configuring network interfaces on 2nd and 3rd level (802.1q vlans, access ports, NIC-bondind, assign IP addresses, dhcp, and interfaces without IP addresses). 
Can work together with Open vSwitch or standart linux way.
At this moment support Centos 6.3+ (RHEL6) and Ubuntu 12.04 or above.

L23network module have a same behavior for both operation systems.


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




L2 network configuation (Open vSwitch only)
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
------------------------

### Simple IP address definition, DHCP or address-less interfaces

    l23network::l3::ifconfig {"eth0": ipaddr=>'192.168.1.1/24'}
    l23network::l3::ifconfig {"xXxXxXx": 
        interface => 'eth1',
        ipaddr    => '192.168.2.1',
        netmask   => '255.255.255.0'
    }
    l23network::l3::ifconfig {"eth2": ipaddr=>'dhcp'}
    l23network::l3::ifconfig {"eth3": ipaddr=>'none'}

Option *ipaddr* can contains IP address, 'dhcp', or 'none' string. In this example we describe configuration of 4 network interfaces:
* Interface *eth0* have short CIDR-notated form of IP address definition.
* Interface *eth1* 
* Interface *eth2* will be configured to use dhcp protocol. 
* Interface *eth3* will be configured as interface without IP address. 
  Often it's need for create "master" interface for 802.1q vlans (in native linux implementation) 
  or as slave interface for bonding.

CIDR-notated form of IP address have more priority, that classic *ipaddr* and *netmask* definition. 
If you ommited *natmask* and not used CIDR-notated form -- will be used 
default *netmask* value as '255.255.255.0'.

### Multiple IP addresses for one interface (aliases)

    l23network::l3::ifconfig {"eth0": 
      ipaddr => ['192.168.0.1/24', '192.168.1.1/24', '192.168.2.1/24']
    }
    
You can pass list of CIDR-notated IP addresses to the *ipaddr* parameter for assign many IP addresses to one interface.
In this case will be created aliases (not a subinterfaces). Array can contains one or more elements.

### UP and DOWN interface order

    l23network::l3::ifconfig {"eth1": 
      ipaddr=>'192.168.1.1/24'
    }
    l23network::l3::ifconfig {"br-ex": 
      ipaddr=>'192.168.10.1/24',
      ifname_order_prefix='ovs'
    }
    l23network::l3::ifconfig {"aaa0": 
      ipaddr=>'192.168.20.1/24', 
      ifname_order_prefix='zzz'
    }

Centos and Ubuntu (at startup OS) start and configure network interfaces in alphabetical order 
interface configuration file names. In example above we change configuration process order 
by *ifname_order_prefix* keyword. We will have this order:

    ifcfg-eth1
    ifcfg-ovs-br-ex
    ifcfg-zzz-aaa0

And the OS will configure interfaces br-ex and aaa0 after eth0

### Default gateway

    l23network::l3::ifconfig {"eth1":
        ipaddr                => '192.168.2.5/24',
        gateway               => '192.168.2.1',
        check_by_ping         => '8.8.8.8',
        check_by_ping_timeout => '30'
    }

In this example we define default *gateway* and options for waiting that network stay up. 
Parameter *check_by_ping* define IP address, that will be pinged. Puppet will be blocked for waiting
response for *check_by_ping_timeout* seconds. 
Parameter *check_by_ping* can be IP address, 'gateway', or 'none' string for disabling checking.
By default gateway will be pinged.

### DNS-specific options

    l23network::l3::ifconfig {"eth1":
        ipaddr          => '192.168.2.5/24',
        dns_nameservers => ['8.8.8.8','8.8.4.4'],
        dns_search      => ['aaa.com','bbb.com'],
        dns_domain      => 'qqq.com'
    }

Also we can specify DNS nameservers, and search list that will be inserted (by resolvconf lib) to /etc/resolv.conf .
Option *dns_domain* implemented only in Ubuntu.

### DHCP-specific options

    l23network::l3::ifconfig {"eth2":
        ipaddr          => 'dhcp',
        dhcp_hostname   => 'compute312',
        dhcp_nowait     => false,
    }



Bonding
-------
### Using standart linux ifenslave bonding
For bonding of two interfaces you need to:
* Configure the bonded interfaces as 'none' (with no IP address)
* Specify that interfaces depend on bond_master interface
* Assign IP address to the bond-master interface
* Specify bond-specific properties for bond_master interface (if you are not happy with defaults)

For example (defaults included):   

    l23network::l3::ifconfig {'bond0':
        ipaddr          => '192.168.232.1',
        netmask         => '255.255.255.0',
        bond_mode       => 0,
        bond_miimon     => 100,
        bond_lacp_rate  => 1,
    } ->
    l23network::l3::ifconfig {'eth1': ipaddr=>'none', bond_master=>'bond0'} ->
    l23network::l3::ifconfig {'eth2': ipaddr=>'none', bond_master=>'bond0'}


More information about bonding of network interfaces you can find in manuals for you operation system:
* https://help.ubuntu.com/community/UbuntuBonding
* http://wiki.centos.org/TipsAndTricks/BondingInterfaces

### Using Open vSwitch
For bonding two interfaces you need:
* Specify OVS bridge
* Specify special resource "bond" and add it to bridge. Specify bond-specific parameters.
* Assign IP address to the newly-created network interface (if need).

In this example we add "eth1" and "eth2" interfaces to bridge "bridge0" as bond "bond1". 

    l23network::l2::bridge{'bridge0': } ->
    l23network::l2::bond{'bond1':
        bridge     => 'bridge0',
        ports      => ['eth1', 'eth2'],
        properties => [
           'lacp=active',
           'other_config:lacp-time=fast'
        ],
    } ->
    l23network::l3::ifconfig {'bond1':
        ipaddr          => '192.168.232.1',
        netmask         => '255.255.255.0',
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

If you are using 802.1q vlans over bonds it is strongly recommended to use the first one.

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
In example above we create two ports with tags 10 and 20, and assign IP address to interface with tag 10:


    l23network::l2::bridge{'bridge0': } ->
    l23network::l2::port{'vl10':
        bridge  => 'bridge0',
        type    => 'internal',
        port_properties => [
            'tag=10'
        ],
    } ->
    l23network::l2::port{'vl20':
        bridge  => 'bridge0',
        type    => 'internal',
        port_properties => [
            'tag=20'
        ],
    } ->
    l23network::l3::ifconfig {'vl10':
        ipaddr  => '192.168.101.1/24',
    } ->
    l23network::l3::ifconfig {'vl20':
        ipaddr  => 'none',    
    } 
    
You can get more details about vlans in open vSwitch at [open vSwitch documentation page](http://openvswitch.org/support/config-cookbooks/vlan-configuration-cookbook/).

**IMPORTANT:** You can't use vlan interface names like vlanXXX if you don't want double-tagging of you network traffic.

---
When I started working on this module I was inspired by https://github.com/ekarlso/puppet-vswitch. Endre, big thanks...
