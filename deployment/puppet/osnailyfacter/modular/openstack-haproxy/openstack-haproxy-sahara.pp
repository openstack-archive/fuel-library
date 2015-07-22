notice('MODULAR: openstack-haproxy-sahara.pp')

$sahara_hash        = hiera_hash('sahara_hash',{})
# NOT enabled by default
$use_sahara         = pick($sahara_hash['enabled'], false)
$public_ssl_hash    = hiera('public_ssl')
$network_metadata   = hiera_hash('network_metadata')
$sahara_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, hiera('sahara_roles')), 'sahara/api')

if ($use_sahara) {
  $server_names        = hiera_array('sahara_names',keys($sahara_address_map))
  $ipaddresses         = hiera_array('sahara_ipaddresses', values($sahara_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure sahara ha proxy
  class { '::openstack::ha::sahara':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl_hash['services'],
  }
}
