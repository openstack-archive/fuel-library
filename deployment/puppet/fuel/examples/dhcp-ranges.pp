notice('MODULAR: dhcp-ranges.pp')

$next_server = hiera('ADMIN_NETWORK')['ipaddress']
$domain_name = hiera('DNS_DOMAIN')
$dns_address = hiera('ADMIN_NETWORK')['ipaddress']
$dhcp_ranges = get_dhcp_ranges(hiera('admin_networks', [{}]))

file { $::provision::params::dhcpd_conf_extra :
  ensure => present,
  content => template('fuel/dhcpd_ranges.erb'),
}
