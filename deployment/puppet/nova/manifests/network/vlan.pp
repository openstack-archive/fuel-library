#vlan.pp
class nova::network::vlan (
  $fixed_range,
  $vlan_interface,
  $public_interface = undef,
  $vlan_start       = '300'
) {

  if $public_interface {
    nova_config { 'public_interface': value => $public_interface }
  }

  nova_config {
    'network_manager':  value => 'nova.network.manager.VlanManager';
    'fixed_range':      value => $fixed_range;
    'vlan_interface':   value => $vlan_interface;
    'vlan_start':       value => $vlan_start;
  }

}
