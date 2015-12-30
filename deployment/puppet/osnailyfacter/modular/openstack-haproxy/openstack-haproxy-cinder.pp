notice('MODULAR: openstack-haproxy-cinder.pp')

$cinder_hash        = hiera_hash('cinder_hash', {})
# enabled by default
$use_cinder         = pick($cinder_hash['enabled'], true)
$public_ssl_hash    = hiera_hash('public_ssl', {})
$ssl_hash           = hiera_hash('use_ssl', {})

$public_ssl         = get_ssl_property($ssl_hash, $public_ssl_hash, 'cinder', 'public', 'usage', false)
$public_ssl_path    = get_ssl_property($ssl_hash, $public_ssl_hash, 'cinder', 'public', 'path', [''])

$internal_ssl       = get_ssl_property($ssl_hash, {}, 'cinder', 'internal', 'usage', false)
$internal_ssl_path  = get_ssl_property($ssl_hash, {}, 'cinder', 'internal', 'path', [''])

$external_lb        = hiera('external_lb', false)

if ($use_cinder and !$external_lb) {
  $cinder_address_map  = get_node_to_ipaddr_map_by_network_role(hiera_hash('cinder_nodes'), 'cinder/api')
  $server_names        = hiera_array('cinder_names', keys($cinder_address_map))
  $ipaddresses         = hiera_array('cinder_ipaddresses', values($cinder_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure cinder ha proxy
  class { '::openstack::ha::cinder':
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
