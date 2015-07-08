notice('MODULAR: openstack-haproxy-radosgw.pp')

$storage_hash                   = hiera_hash('storage', {})

if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $use_swift = true
} else {
  $use_swift = false
}
if !($use_swift) and ($storage_hash['objects_ceph']) {
  $use_radosgw = true
} else {
  $use_radosgw = false
}

if ($use_radosgw) {
  $haproxy_nodes       = pick(hiera('rgw_servers', undef),
                              hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick(hiera_array('radosgw_server_names', undef),
                              filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('radosgw_ipaddresses', undef),
                              filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure radosgw ha proxy
  class { '::openstack::ha::radosgw':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
