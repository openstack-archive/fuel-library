# flatdhcp.pp
class nova::network::flatdhcp (
  $public_interface,
  $flat_interface,
  $flat_dhcp_start,
  $flat_injected = 'false',
  $dhcpbridge = '/usr/bin/nova-dhcpbridge',
  $dhcpbridge_flagfile='/etc/nova/nova.conf',
  $enabled = 'true'
) {
  # we only need to setup configuration, nova does the rest
  class { 'nova::network':
    enabled => $enabled,
  }

  nova_config {
    'public_interface': value => $public_interface;
    'flat_interface': value => $flat_interface;
    'flat_dhcp_start': value => $flat_dhcp_start;
    'flat_injected': value => $flat_injected;
    'dhcpbridge': value => $dhcpbridge;
    'dhcpbridge_flagfile': value => $dhcpbridge_flagfile;
  }

}
