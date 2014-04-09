#
class nova::network::flatdhcp (
  $fixed_range,
  $flat_interface      = undef,
  $public_interface    = undef,
  $flat_network_bridge = 'br100',
  $force_dhcp_release  = true,
  $flat_injected       = false,
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
    'DEFAULT/network_manager':     value => 'nova.network.manager.FlatDHCPManager';
    'DEFAULT/fixed_range':         value => $fixed_range;
    'DEFAULT/flat_interface':      value => $flat_interface;
    'DEFAULT/flat_network_bridge': value => $flat_network_bridge;
    'DEFAULT/force_dhcp_release':  value => $force_dhcp_release;
    'DEFAULT/flat_injected':       value => $flat_injected;
    'DEFAULT/dhcp_domain':         value => $dhcp_domain;
    'DEFAULT/dhcpbridge':          value => $dhcpbridge;
    'DEFAULT/dhcpbridge_flagfile': value => $dhcpbridge_flagfile;
  }

}
