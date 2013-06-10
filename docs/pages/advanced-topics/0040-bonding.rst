L23network 
----------

NOTE:  THIS DOCUMENT HAS NOT BEEN EDITED AND IS NOT READY FOR PUBLIC CONSUMPTION.

Puppet module for configuring network interfaces on 2nd and 3rd level (802.1q vlans, access ports, NIC-bonding, assign IP addresses, dhcp, and interfaces without IP addresses). 

Can work together with Open vSwitch or standard linux way.

At this moment we support Centos 6.3 (RHEL6) and Ubuntu 12.04 or above.


Usage
^^^^^

Place this module at /etc/puppet/modules or on another path that contains your puppet modules.

Include L23network module and initialize it. I recommend to do it in an early stage::

    #Network configuration
    stage {'netconfig':
      before  => Stage['main'],
    }
    class {'l23network': stage=> 'netconfig'}

If you do not plan to use Open vSwitch -- you can disable it::

    class {'l23network': use_ovs=>false, stage=> 'netconfig'}




L2 network configuation (Open vSwitch only)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Current layout is:
* *bridges* -- A "Bridge" is a virtual ethernet L2 switch. You can plug ports into it.
* *ports* -- A Port is an interface you plug into the bridge (switch). It's a virtual.  (virtual what?)
* *interface* -- A physical implementation of port.

Then in your manifest you can either use the things as parameterized classes::

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
If you do not define type for port (or define '') -- ovs-vsctl will have default behavior 
(see http://openvswitch.org/cgi-bin/ovsman.cgi?page=utilities%2Fovs-vsctl.8).

You can use *skip_existing* option if you do not want to interrupt configuration while adding an existing port or bridge.



L3 network configuration
^^^^^^^^^^^^^^^^^^^^^^^^
  ::

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
* Interface *eth3* will be configured as interface without IP address. Often you will need to create "master" interface for 802.1q vlans (in native linux implementation) or as slave interface for bonding.

CIDR-notated form of IP address has more priority, that classic *ipaddr* and *netmask* definition. 
If you omitted *natmask* and did not use CIDR-notated form -- default *netmask* value will be used as '255.255.255.0'.::

    ### Multiple IP addresses for one interface (aliases) 

    l23network::l3::ifconfig {"eth0": 
      ipaddr => ['192.168.0.1/24', '192.168.1.1/24', '192.168.2.1/24']
    }
    
You can pass a list of CIDR-notated IP addresses to the *ipaddr* parameter to assign many IP addresses to one interface.  This will create aliases (not subinterfaces). Array can contain one or more elements. ::

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
by interface configuration file names. In the example above we change configuration process order by *ifname_order_prefix* keyword. We will have this order::

    ifcfg-eth1
    ifcfg-ovs-br-ex
    ifcfg-zzz-aaa0

And OS will configure interfaces br-ex and aaa0 after eth0::

    ### Default gateway

    l23network::l3::ifconfig {"eth1":
        ipaddr                => '192.168.2.5/24',
        gateway               => '192.168.2.1',
        check_by_ping         => '8.8.8.8',
        check_by_ping_timeout => '30'
    }

In this example we define default *gateway* and options for waiting  so that the network stays up. 
Parameter *check_by_ping* define IP address, that will be pinged. Puppet will be blocked for waiting response for *check_by_ping_timeout* seconds. 
Parameter *check_by_ping* can be IP address, 'gateway', or 'none' string for disabling checking.
By default gateway will be pinged. ::

    ### DNS-specific options

    l23network::l3::ifconfig {"eth1":
        ipaddr          => '192.168.2.5/24',
        dns_nameservers => ['8.8.8.8','8.8.4.4'],
        dns_search      => ['aaa.com','bbb.com'],
        dns_domain      => 'qqq.com'
    }

Also we can specify DNS nameservers, and search list that will be inserted (by resolvconf lib) to /etc/resolv.conf .
Option *dns_domain* implemented only in Ubuntu. ::

    ### DHCP-specific options

    l23network::l3::ifconfig {"eth2":
        ipaddr          => 'dhcp',
        dhcp_hostname   => 'compute312',
        dhcp_nowait     => false,
    }



Bonding
^^^^^^^

### Using standard linux bond (ifenslave)
For bonding two interfaces you need to:
* Specify these interfaces as interfaces without IP addresses
* Specify that the interfaces depend on the master-bond-interface
* Assign IP address to the master-bond-interface.
* Specify bond-specific properties for master-bond-interface (if defaults are not suitable for you)

for example (defaults included)::   

    l23network::l3::ifconfig {'eth1': ipaddr=>'none', bond_master=>'bond0'} ->
    l23network::l3::ifconfig {'eth2': ipaddr=>'none', bond_master=>'bond0'} ->
    l23network::l3::ifconfig {'bond0':
        ipaddr          => '192.168.232.1',
        netmask         => '255.255.255.0',
        bond_mode       => 0,
        bond_miimon     => 100,
        bond_lacp_rate  => 1,
    }


More information about bonding network interfaces you can get in manuals for your operating system:
* https://help.ubuntu.com/community/UbuntuBonding
* http://wiki.centos.org/TipsAndTricks/BondingInterfaces

### Using Open vSwitch
For bonding two interfaces you need:
* Specify OVS bridge
* Specify special resource "bond" and add it to bridge. Specify bond-specific parameters.
* Assign IP address to the newly-created network interface (if needed).

In this example we add "eth1" and "eth2" interfaces to bridge "bridge0" as bond "bond1". ::

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

Open vSwitch provides lot of parameters for different configurations. 
We can specify them in the "properties" option as a list of parameter=value 
(or parameter:key=value) strings.
The most of them you can see in [open vSwitch documentation page](http://openvswitch.org/support/).



802.1q vlan access ports
^^^^^^^^^^^^^^^^^^^^^^^^

### Using standard linux way
We can use tagged vlans over ordinary network interfaces (or over bonds). 
L23networks support two variants of naming vlan interfaces:
* *vlanXXX* -- 802.1q tag gives from the vlan interface name, but you need to specify 
parent interface name in the **vlandev** parameter.
* *eth0.101* -- 802.1q tag and parent interface name gives from the vlan interface name

If you need to use 802.1q vlans over bonds -- you can use only the first variant.

In this example we can see both variants: ::

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

### Using Open vSwitch
In the Open vSwitch all internal traffic is virtually tagged.
For creating the 802.1q tagged access port you need to specify vlan tag when adding a port to a bridge. 
In this example we create two ports with tags 10 and 20, and assign an IP address to interface with tag 10::

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
    
Information about vlans in open vSwitch you can get in [open vSwitch documentation page](http://openvswitch.org/support/config-cookbooks/vlan-configuration-cookbook/).

**IMPORTANT:** You can't use vlan interface names like vlanXXX if you do not want double-tagging of your network traffic.

---
When I began to write this module, I checked https://github.com/ekarlso/puppet-vswitch. Elcarso, big thanks...


