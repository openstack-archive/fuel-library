#vlan.pp
class nova::network::vlan (
  $fixed_range,
  $vlan_interface,
  $public_interface    = undef,
  $vlan_start          = '300',
  $force_dhcp_release  = true,
  $dhcp_domain         = 'novalocal',
  $dhcpbridge          = '/usr/bin/nova-dhcpbridge',
  $dhcpbridge_flagfile = '/etc/nova/nova.conf'
) {

  if $public_interface {
    nova_config { 'public_interface': value => $public_interface }
  }

  nova_config {
    'network_manager':     value => 'nova.network.manager.VlanManager';
    'fixed_range':         value => $fixed_range;
    'vlan_interface':      value => $vlan_interface;
    'vlan_start':          value => $vlan_start;
    'force_dhcp_release':  value => $force_dhcp_release;
    'dhcp_domain':         value => $dhcp_domain;
    'dhcpbridge':          value => $dhcpbridge;
    'dhcpbridge_flagfile': value => $dhcpbridge_flagfile;
  }

}
