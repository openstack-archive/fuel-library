# == Define: l23network::l3::create_br_iface
#
# Create L2 ovs bridge, clean IPs from interface and add IP address to this
# bridge
#
# === Parameters
#
# [*bridge*]
#   Bridge name
#
# [*interface*]
#   Interface that will be added to the bridge. 
#   If you set the interface parameter as an array of interface names 
#   then Open vSwitch will create bond with given interfaces.
#   In this case you must set ovs_bond_name and ovs_bond_properties parameters.
#
# [*ipaddr*]
#   IP address for port in bridge.
#
# [*netmask*]
#   Network mask.
#
# [*gateway*]
#   You can specify default gateway IP address, or 'save' for save default route 
#   if it lies through this interface now.
#
# [*dns_nameservers*]
#   Dns nameservers to use
# 
# [*dns_domain*]
#   Describe DNS domain
#
# [*dns_search*]
#   DNS domain to search for
#
# [*save_default_gateway*]
#   If current network configuration contains a gateway parameter
#   this option will try to save it.
#   DEPRECATED!!! use gateway=>'save'
#
define l23network::l3::create_br_iface (
    $interface,
    $ipaddr,
    $bridge       = $name,
    $netmask      = '255.255.255.0',
    $gateway      = undef,
    $se           = true,
    $external_ids = '',
    $dns_nameservers      = undef,
    $dns_domain           = undef,
    $dns_search           = undef,
    $save_default_gateway = false,
    $lnx_interface_vlandev    = undef,
    $lnx_interface_bond_mode      = undef,
    $lnx_interface_bond_miimon    = 100,
    $lnx_interface_bond_lacp_rate = 1,
    $ovs_bond_name          = 'bond0',
    $ovs_bond_properties    = [],
    $interface_order_prefix = false,
){
    if ! $::l23network::l2::use_ovs {
      fail('You must enable Open vSwitch by setting the l23network::l2::use_ovs to true.')
    }
    
    if ! $external_ids {
      $ext_ids = "bridge-id=${bridge}"
    }
    #
    if $gateway {
      $gateway_ip_address_for_newly_created_interface = $gateway
    } elsif ($save_default_gateway or $gateway == 'save') and $::l3_default_route_interface == $interface {
      $gateway_ip_address_for_newly_created_interface = 'save'
    } else {
      $gateway_ip_address_for_newly_created_interface = undef
    }
    # Build ovs bridge
    l23network::l2::bridge {"$bridge":
      skip_existing => $se,
      external_ids  => $ext_ids,
    }
    if is_array($interface) {
      # Build an ovs bridge containing ovs bond with given interfaces
      l23network::l2::bond {"$ovs_bond_name":
        bridge        => $bridge,
        ports         => $interface,
        properties    => $ovs_bond_properties,
        skip_existing => $se,
        require       => L23network::L2::Bridge["$bridge"]
      } ->
      l23network::l3::ifconfig {$interface: # no quotes here, $interface _may_be_ array!!!
        ipaddr    => 'none',
        ifname_order_prefix => '0',
        require   => L23network::L2::Bond["$ovs_bond_name"],
        before    => L23network::L3::Ifconfig["$bridge"]
      }
    } else {
      # Build an ovs bridge containing one interface
      l23network::l2::port {$interface:
        bridge        => $bridge,
        skip_existing => $se,
        require       => L23network::L2::Bridge["$bridge"]
      } ->
      l23network::l3::ifconfig {"$interface": # USE quotes!!!!!
        ipaddr    => 'none',
        vlandev   => $lnx_interface_vlandev,
        bond_mode      => $lnx_interface_bond_mode,
        bond_miimon    => $lnx_interface_bond_miimon,
        bond_lacp_rate => $lnx_interface_bond_lacp_rate,
        ifname_order_prefix => $interface_order_prefix,
        require   => L23network::L2::Port["$interface"],
        before    => L23network::L3::Ifconfig["$bridge"]
      }
    }
    l23network::l3::ifconfig {"$bridge":
      ipaddr              => $ipaddr,
      netmask             => $netmask,
      gateway             => $gateway_ip_address_for_newly_created_interface,
      dns_nameservers     => $dns_nameservers,
      dns_domain          => $dns_domain,
      dns_search          => $dns_search,
      ifname_order_prefix => 'ovs',
    }
}
