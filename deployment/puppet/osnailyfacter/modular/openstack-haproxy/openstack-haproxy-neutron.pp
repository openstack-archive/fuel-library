notice('MODULAR: openstack-haproxy-neutron.pp')

# NOT enabled by default
$use_neutron         = hiera('use_neutron', false)
$public_ssl_hash     = hiera('public_ssl')

$neutron_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('neutron_nodes'), 'neutron/api')
if ($use_neutron) {
  $server_names        = hiera_array('neutron_names', keys($neutron_address_map))
  $ipaddresses         = hiera_array('neutron_ipaddresses', values($neutron_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure neutron ha proxy
  class { '::openstack::ha::neutron':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl_hash['services'],
  }
}
