notice('MODULAR: openstack-haproxy-swift.pp')

$storage_hash = hiera_hash('storage', {})

if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $use_swift = true
} else {
  $use_swift = false
}

if ($use_swift) {
  $swift_proxies = hiera('swift_proxies', $haproxy_nodes)

  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick(hiera_array('swift_server_names', undef),
                              filter_hash(pick($swift_proxies, $haproxy_nodes), 'name'))
  $ipaddresses         = pick(hiera_array('swift_ipaddresses', undef),
                              filter_hash($haproxy_nodes, 'storage_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure swift ha proxy
  class { '::openstack::ha::swift':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
