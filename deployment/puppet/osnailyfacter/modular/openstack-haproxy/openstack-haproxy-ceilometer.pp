notice('MODULAR: openstack-haproxy-ceilometer.pp')

$ceilometer_hash         = hiera_hash('ceilometer',{})
# NOT enabled by default
$use_ceilometer          = pick($ceilometer_hash['enabled'], false)
$public_ssl_hash         = hiera('public_ssl')
$ceilometer_address_map  = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceilometer_nodes'), 'ceilometer/api')

if ($use_ceilometer) {
  $server_names        = hiera_array('ceilometer_names', keys($ceilometer_address_map))
  $ipaddresses         = hiera_array('ceilometer_ipaddresses', values($ceilometer_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure ceilometer ha proxy
  class { '::openstack::ha::ceilometer':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl_hash['services'],
  }
}
