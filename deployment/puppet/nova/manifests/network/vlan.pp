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

  if $::osfamily == 'RedHat' and $::operatingsystem != 'Fedora' {
    package { 'dnsmasq-utils': ensure => present }
  }

  if $public_interface {
    nova_config { 'DEFAULT/public_interface': value => $public_interface }
  }

  nova_config {
    'DEFAULT/network_manager':     value => 'nova.network.manager.VlanManager';
    'DEFAULT/fixed_range':         value => $fixed_range;
    'DEFAULT/vlan_interface':      value => $vlan_interface;
    'DEFAULT/vlan_start':          value => $vlan_start;
    'DEFAULT/force_dhcp_release':  value => $force_dhcp_release;
    'DEFAULT/dhcp_domain':         value => $dhcp_domain;
    'DEFAULT/dhcpbridge':          value => $dhcpbridge;
    'DEFAULT/dhcpbridge_flagfile': value => $dhcpbridge_flagfile;
  }

}
