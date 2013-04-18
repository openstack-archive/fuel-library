Puppet module for configuring L2 and L3 networks.
Based on open vSwitch and iproute2. 

L2 network configuation
-----------------------

Current layout is:
bridges - A "Bridge" is basically the thing you plug ports / interfaces into.
ports - A Port is a interface you plug into the bridge (switch).

USAGE:
Place this directory at:
<your module directory of choice>/l23network

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

---
When I began write this module, I seen to https://github.com/ekarlso/puppet-vswitch. Elcarso, big thanks...
