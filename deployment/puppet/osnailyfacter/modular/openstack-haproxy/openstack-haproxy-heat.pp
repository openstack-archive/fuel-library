notice('MODULAR: openstack-haproxy-heat.pp')

$heat_hash        = hiera_hash('heat', {})
# enabled by default
$use_heat         = pick($heat_hash['enabled'], true)
$public_ssl_hash  = hiera('public_ssl')
$ssl_hash         = hiera('use_ssl', {})
if try_get_value($ssl_hash, 'heat_public', false) {
  $public_ssl = true
  $public_ssl_path = '/var/lib/astute/haproxy/public_heat.pem'
} elsif $public_ssl_hash['services'] {
  $public_ssl = true
  $public_ssl_path = '/var/lib/astute/haproxy/public_haproxy.pem'
} else {
  $public_ssl = false
  $public_ssl_path = ''
}

if try_get_value($ssl_hash, 'heat_internal', false) {
  $internal_ssl = true
  $internal_ssl_path = '/var/lib/astute/haproxy/internal_heat.pem'
} else {
  $internal_ssl = false
  $internal_ssl_path = ''
}
$network_metadata = hiera_hash('network_metadata')
$heat_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, hiera('heat_roles')), 'heat/api')

if ($use_heat) {
  $server_names        = hiera_array('heat_names',keys($heat_address_map))
  $ipaddresses         = hiera_array('heat_ipaddresses', values($heat_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

# configure heat ha proxy
  class { '::openstack::ha::heat':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl,
    public_ssl_path     => $public_ssl_path,
    internal_ssl        => $internal_ssl,
    internal_ssl_path   => $internal_ssl_path,
  }
}
