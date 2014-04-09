# == Class: nova::network::flat
#
# Configuration settings for nova flat network
#
# === Parameters:
#
# [*fixed_range*]
#   (required) The IPv4 CIDR for the network
#
# [flat_interface]
#   (optional) Interface that flat network will use for bridging
#   Defaults to undef
#
# [*public_interface*]
#   (optional) The interface to use for public traffic
#   Defaults to undef
#
# [flat_network_bridge]
#   (optional) The name of the bridge to use
#   Defaults to 'br100'
#
class nova::network::flat (
  $fixed_range,
  $flat_interface=undef,
  $public_interface   = undef,
  $flat_network_bridge = 'br100'
) {

  if $public_interface {
    nova_config { 'DEFAULT/public_interface': value => $public_interface }
  }

  nova_config {
    'DEFAULT/network_manager':     value => 'nova.network.manager.FlatManager';
    'DEFAULT/fixed_range':         value => $fixed_range;
    'DEFAULT/flat_interface':      value => $flat_interface;
    'DEFAULT/flat_network_bridge': value => $flat_network_bridge;
  }

}
