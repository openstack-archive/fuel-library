notice('MODULAR: openstack-haproxy-radosgw.pp')

$storage_hash     = hiera_hash('storage', {})
$rgw_servers      = hiera('rgw_servers', hiera('controllers'))
$public_ssl_hash  = hiera('public_ssl')

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
  $server_names        = pick(hiera_array('radosgw_server_names', undef),
                              filter_hash($rgw_servers, 'name'))
  $ipaddresses         = pick(hiera_array('radosgw_ipaddresses', undef),
                              filter_hash($rgw_servers, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure radosgw ha proxy
  class { '::openstack::ha::radosgw':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl_hash['services'],
  }
}
