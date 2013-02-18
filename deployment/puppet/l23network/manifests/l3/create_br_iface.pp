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
define l23network::l3::create_br_iface (
    $interface,
    $bridge,
    $ipaddr,
    $netmask = '',
    $se = true,
    $external_ids = '',
){
    if ! $external_ids {
      $ext_ids = "bridge-id=${bridge}"
    }
    #
    if $::l3_default_route_interface == $interface {
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
      require   => L23network::L2::Port[$interface],
    }
    l23network::l3::ifconfig {$bridge:
      ipaddr              => $ipaddr,
      netmask             => $netmask,
      gateway             => $gateway_ip_address_for_newly_created_interface,
      ifname_order_prefix => 'ovs',
      require             => L23network::L3::Ifconfig[$interface],
    }
}
