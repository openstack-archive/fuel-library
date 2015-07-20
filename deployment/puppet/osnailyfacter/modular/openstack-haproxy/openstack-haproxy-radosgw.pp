notice('MODULAR: openstack-haproxy-radosgw.pp')

$network_metadata = hiera_hash('network_metadata')
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

if ($use_radosgw and $rgw_servers) {
  $rgw_address_map     = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_rgw_nodes'), 'ceph/radosgw')
  $server_names        = hiera_array('radosgw_server_names', keys($rgw_address_map))
  $ipaddresses         = hiera_array('radosgw_ipaddresses', values($rgw_address_map))
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
