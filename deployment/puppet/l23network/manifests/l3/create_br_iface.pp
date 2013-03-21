# == Define: l23network::l3::create_br_iface
#
# Creating L2 ovs bridge, cleaning IPs from interface and add IP address to this
# bridge
#
# === Parameters
#
# [*bridge*]
#   Bridge name
#
# [*interface*]
#   Interface, that will be added to the bridge.
#
# [*ipaddr*]
#   IP address for port in bridge.
#
# [*netmask*]
#   Network mask.
#
# [*gateway*]
#   You can specify default gateway. 
#
# [*save_default_gateway*]
#   If current network configuration contains a default gateway 
#   this option allow try to save it.
#
define l23network::l3::create_br_iface (
    $interface,
    $bridge,
    $ipaddr,
    $netmask      = '255.255.255.0',
    $gateway      = undef,
    $se           = true,
    $external_ids = '',
    $dns_nameservers      = undef,
    $save_default_gateway = false,
    $interface_vlandev    = undef,
    $interface_bond_mode      = undef,
    $interface_bond_miimon    = 100,
    $interface_bond_lacp_rate = 1,
    $interface_order_prefix   = false,
){
    if ! $external_ids {
      $ext_ids = "bridge-id=${bridge}"
    }
    #
    if $gateway {
      $gateway_ip_address_for_newly_created_interface = $gateway
    } elsif $save_default_gateway and $::l3_default_route_interface == $interface {
      $gateway_ip_address_for_newly_created_interface = $::l3_default_route
    } else {
      $gateway_ip_address_for_newly_created_interface = undef
    }
    l23network::l2::bridge {$bridge:
      skip_existing => $se,
      external_ids  => $ext_ids,
    }
    l23network::l2::port {$interface:
      bridge        => $bridge,
      skip_existing => $se,
      require       => L23network::L2::Bridge[$bridge]
    }
    l23network::l3::ifconfig {$interface:
      ipaddr    => 'none',
      vlandev   => $interface_vlandev,
      require   => L23network::L2::Port[$interface],
      bond_mode      => $interface_bond_mode,
      bond_miimon    => $interface_bond_miimon,
      bond_lacp_rate => $interface_bond_lacp_rate,
      ifname_order_prefix => $interface_order_prefix,
    }
    l23network::l3::ifconfig {$bridge:
      ipaddr              => $ipaddr,
      netmask             => $netmask,
      gateway             => $gateway_ip_address_for_newly_created_interface,
      dns_nameservers     => $dns_nameservers,
      ifname_order_prefix => 'ovs',
      require             => L23network::L3::Ifconfig[$interface],
    }
}
