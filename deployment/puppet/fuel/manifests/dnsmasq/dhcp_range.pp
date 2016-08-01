#
# fuel::dnsmasq::dhcp_range creates config files in /etc/dnsmasq.d/
#
# [next_server] IP address that will be used as PXE tftp server
# [dhcp_start_address] First address of dhcp range
# [dhcp_end_address] Last address of dhcp range
# [dhcp_netmask] Netmask of the network
# [dhcp_gateway] Gateway address for installed nodes
# [lease_time] DHCP lease time
# [file_header] File header for comments

define fuel::dnsmasq::dhcp_range(
  $dhcp_start_address = '10.0.0.201',
  $dhcp_end_address   = '10.0.0.254',
  $dhcp_netmask       = '255.255.255.0',
  $dhcp_gateway       = $::ipaddress,
  $listen_address     = $::ipaddress,
  $file_header        = undef,
  $lease_time         = '120m',
  $next_server        = $::ipaddress,
){
  $range_name = $name
  file { "/etc/dnsmasq.d/${name}.conf":
    content => template('fuel/dnsmasq.dhcp-range.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
}
