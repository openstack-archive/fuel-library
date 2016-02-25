notice('MODULAR: dhcp-ranges.pp')

$admin_networks = hiera('admin_networks', [{}])
$admin_network  = hiera('ADMIN_NETWORK')

Fuel::Dnsmasq::Dhcp_range <||> {
  next_server => $admin_network['ipaddress'],
}

# Ensure dir with purge and recurse to remove configs for
# non-existing (removed) nodegroups and ip ranges
file { '/etc/dnsmasq.d':
  ensure  => 'directory',
  recurse => true,
  purge   => true,
}

# Create admin networks dhcp-range files except for 'default' nodegroup
# by creating Fuel::Dnsmasq::Dhcp_range puppet resources
create_dnsmasq_dhcp_ranges($admin_networks)
