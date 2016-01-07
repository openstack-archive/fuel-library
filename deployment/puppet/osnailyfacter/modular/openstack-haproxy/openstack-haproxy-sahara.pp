notice('MODULAR: openstack-haproxy-sahara.pp')

$sahara_hash        = hiera_hash('sahara_hash',{})
# NOT enabled by default
$use_sahara         = pick($sahara_hash['enabled'], false)
$public_ssl_hash    = hiera('public_ssl')
$ssl_hash           = hiera_hash('use_ssl', {})

$public_ssl         = get_ssl_property($ssl_hash, $public_ssl_hash, 'sahara', 'public', 'usage', false)
$public_ssl_path    = get_ssl_property($ssl_hash, $public_ssl_hash, 'sahara', 'public', 'path', [''])

$internal_ssl       = get_ssl_property($ssl_hash, {}, 'sahara', 'internal', 'usage', false)
$internal_ssl_path  = get_ssl_property($ssl_hash, {}, 'sahara', 'internal', 'path', [''])

$network_metadata   = hiera_hash('network_metadata')
$sahara_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, hiera('sahara_roles')), 'sahara/api')
$external_lb        = hiera('external_lb', false)

if ($use_sahara and !$external_lb) {
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
    public_ssl          => $public_ssl,
    public_ssl_path     => $public_ssl_path,
    internal_ssl        => $internal_ssl,
    internal_ssl_path   => $internal_ssl_path,
  }
}
