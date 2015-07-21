notice('MODULAR: openstack-haproxy-cinder.pp')

$network_metadata = hiera_hash('network_metadata')
$cinder_hash      = hiera_hash('cinder_hash', {})
# enabled by default
$use_cinder = pick($cinder_hash['enabled'], true)
$public_ssl_hash = hiera('public_ssl')

$cinder_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('cinder_nodes'), 'cinder/api')
if ($use_cinder) {
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
    public_ssl          => $public_ssl_hash['services'],
  }
}
