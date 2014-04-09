# Configuration settings for nova flat network
# ==Parameters
# [flat_interface] Interface that flat network will use for bridging.
# [flat_network_bridge] Name of bridge.
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
