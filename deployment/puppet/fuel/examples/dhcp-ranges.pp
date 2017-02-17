notice('MODULAR: dhcp-ranges.pp')

$admin_network = hiera('ADMIN_NETWORK')
$next_server = $admin_network['ipaddress']
$domain_name = hiera('DNS_DOMAIN')
$dns_address = $admin_network['ipaddress']
$dhcp_ranges = get_dhcp_ranges(hiera('admin_networks', [{}]))

file { $::provision::params::dhcpd_conf_extra :
  ensure => present,
  content => template('fuel/dhcpd_ranges.erb'),
}
