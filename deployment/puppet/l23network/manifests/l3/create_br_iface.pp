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
#   Interface, that will be added to the bridge. If You set array of interface names -- 
#   Open vSwitch bond will be builded on its. In this case You must set ovs_bond_name and
#   ovs_bond_options options.3
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
# [*dns_nameservers*]
#   Dns nameservers to use
# 
# [*dns_domain*]
#   describe DNS domain
#
# [*dns_search*]
#   DNS domain to search for
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
    $ovs_bond_name    = 'bond0',
    $ovs_bond_options = [],
    $interface_order_prefix = false,
){
    if ! $::l23network::l2::use_ovs {
      fail('You need enable using Open vSwitch. You yourself has prohibited it.')
    }
    
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
    # Build ovs bridge
    l23network::l2::bridge {"$bridge":
      skip_existing => $se,
      external_ids  => $ext_ids,
    }
    if is_array($interface) {
      # Build ovs bridge, contains ovs bond with givet interfaces
      l23network::l2::bond {"$ovs_bond_name":
        bridge        => $bridge,
        ports         => $interface,
        options       => $ovs_bond_options,
        skip_existing => $se,
        require       => L23network::L2::Bridge["$bridge"]
      } ->
      l23network::l3::ifconfig {$interface: # do not quotas here, $interface may be array!!!
        ipaddr    => 'none',
        ifname_order_prefix => '0',
        require   => L23network::L2::Bond["$ovs_bond_name"],
        before    => L23network::L3::Ifconfig["$bridge"]
      }
    } else {
      # Build ovs bridge, contains one interface
      l23network::l2::port {$interface:
        bridge        => $bridge,
        skip_existing => $se,
        require       => L23network::L2::Bridge["$bridge"]
      } ->
      l23network::l3::ifconfig {"$interface": # USE quotas!!!!!
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
