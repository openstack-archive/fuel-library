$fuel_settings = parseyaml($astute_settings_yaml)
$admin_network = $::fuel_settings['ADMIN_NETWORK']

nailgun::dnsmasq::dhcp_range {'default':
  dhcp_start_address => $admin_network['dhcp_pool_start'],
  dhcp_end_address   => $admin_network['dhcp_pool_end'],
  dhcp_netmask       => $admin_network['netmask'],
  dhcp_gateway       => $admin_network['dhcp_gateway'],
  next_server        => $admin_network['ipaddress'],
}
