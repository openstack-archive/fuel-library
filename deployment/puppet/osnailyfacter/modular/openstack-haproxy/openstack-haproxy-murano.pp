notice('MODULAR: openstack-haproxy-murano.pp')

$murano_hash        = hiera_hash('murano_hash',{})
# NOT enabled by default
$use_murano         = pick($murano_hash['enabled'], false)
$public_ssl_hash    = hiera('public_ssl')
$network_metadata   = hiera_hash('network_metadata')
$murano_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, hiera('murano_roles')), 'murano/api')

if ($use_murano) {
  $server_names        = hiera_array('murano_names',keys($murano_address_map))
  $ipaddresses         = hiera_array('murano_ipaddresses', values($murano_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure murano ha proxy
  class { '::openstack::ha::murano':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl_hash['services'],
  }
}
