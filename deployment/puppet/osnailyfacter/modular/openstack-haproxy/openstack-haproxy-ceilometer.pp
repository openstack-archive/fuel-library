notice('MODULAR: openstack-haproxy-ceilometer.pp')

$ceilometer_hash         = hiera_hash('ceilometer',{})
# NOT enabled by default
$use_ceilometer          = pick($ceilometer_hash['enabled'], false)
$public_ssl_hash         = hiera('public_ssl')
$ssl_hash                = hiera_hash('use_ssl', {})
$ceilometer_address_map  = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceilometer_nodes'), 'ceilometer/api')

$public_ssl              = get_ssl_property($ssl_hash, $public_ssl_hash, 'ceilometer', 'public', 'usage', false)
$public_ssl_path         = get_ssl_property($ssl_hash, $public_ssl_hash, 'ceilometer', 'public', 'path', [''])

$internal_ssl            = get_ssl_property($ssl_hash, {}, 'ceilometer', 'internal', 'usage', false)
$internal_ssl_path       = get_ssl_property($ssl_hash, {}, 'ceilometer', 'internal', 'path', [''])

$external_lb             = hiera('external_lb', false)

if ($use_ceilometer and !$external_lb) {
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
    public_ssl          => $public_ssl,
    public_ssl_path     => $public_ssl_path,
    internal_ssl        => $internal_ssl,
    internal_ssl_path   => $internal_ssl_path,
  }
}
