notice('MODULAR: openstack-haproxy-keystone.pp')

$network_metadata      = hiera_hash('network_metadata')
$keystone_hash         = hiera_hash('keystone', {})
# enabled by default
$use_keystone          = pick($keystone_hash['enabled'], true)
$public_ssl_hash       = hiera('public_ssl')
$ssl_hash              = hiera_hash('use_ssl', {})

$public_ssl            = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'usage', false)
$public_ssl_path       = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'path', [''])

$internal_ssl          = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'usage', false)
$internal_ssl_path     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'path', [''])

$admin_ssl             = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'usage', false)
$admin_ssl_path        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'path', [''])

#todo(sv): change to 'keystone' as soon as keystone as node-role was ready
$keystones_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller']), 'keystone/api')

$external_lb = hiera('external_lb', false)

if ($use_keystone and !$external_lb) {
  $server_names        = pick(hiera_array('keystone_names', undef),
                              keys($keystones_address_map))
  $ipaddresses         = pick(hiera_array('keystone_ipaddresses', undef),
                              values($keystones_address_map))
  $public_virtual_ip   = pick(hiera('public_service_endpoint', undef), hiera('public_vip'))
  $internal_virtual_ip = pick(hiera('service_endpoint', undef), hiera('management_vip'))


  # configure keystone ha proxy
  class { '::openstack::ha::keystone':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl,
    public_ssl_path     => $public_ssl_path,
    internal_ssl        => $internal_ssl,
    internal_ssl_path   => $internal_ssl_path,
    admin_ssl           => $admin_ssl,
    admin_ssl_path      => $admin_ssl_path,
  }
}
