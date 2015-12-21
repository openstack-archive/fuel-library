notice('MODULAR: openstack-haproxy-swift.pp')

$network_metadata  = hiera_hash('network_metadata')
$storage_hash      = hiera_hash('storage', {})
$swift_proxies     = hiera_hash('swift_proxies', undef)
$public_ssl_hash   = hiera('public_ssl')
$ssl_hash          = hiera_hash('use_ssl', {})

$public_ssl        = get_ssl_property($ssl_hash, $public_ssl_hash, 'swift', 'public', 'usage', false)
$public_ssl_path   = get_ssl_property($ssl_hash, $public_ssl_hash, 'swift', 'public', 'path', [''])

$internal_ssl      = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'usage', false)
$internal_ssl_path = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'path', [''])

$ironic_hash       = hiera_hash('ironic', {})

$external_lb       = hiera('external_lb', false)

if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $use_swift = true
} else {
  $use_swift = false
}

$swift_proxies_address_map = get_node_to_ipaddr_map_by_network_role($swift_proxies, 'swift/api')

if ($use_swift and !$external_lb) {

  $server_names        = hiera_array('swift_server_names', keys($swift_proxies_address_map))
  $ipaddresses         = hiera_array('swift_ipaddresses', values($swift_proxies_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  if $ironic_hash['enabled'] {
    $baremetal_virtual_ip = $network_metadata['vips']['baremetal']['ipaddr']
  }

  prepare_network_config(hiera_hash('network_scheme'))

  # Check proxy and storage daemons binds on the same ip address
  $swift_api_ipaddr     = get_network_role_property('swift/api', 'ipaddr')
  $swift_storage_ipaddr = get_network_role_property('swift/replication', 'ipaddr')
  $bind_to_one          = ($swift_api_ipaddr == $swift_storage_ipaddr)

  # configure swift ha proxy
  class { '::openstack::ha::swift':
    internal_virtual_ip  => $internal_virtual_ip,
    ipaddresses          => $ipaddresses,
    public_virtual_ip    => $public_virtual_ip,
    server_names         => $server_names,
    public_ssl           => $public_ssl,
    public_ssl_path      => $public_ssl_path,
    internal_ssl         => $internal_ssl,
    internal_ssl_path    => $internal_ssl_path,
    baremetal_virtual_ip => $baremetal_virtual_ip,
    bind_to_one          => $bind_to_one,
  }
}
