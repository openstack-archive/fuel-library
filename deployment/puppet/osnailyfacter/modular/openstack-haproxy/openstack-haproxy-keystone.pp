notice('MODULAR: openstack-haproxy-keystone.pp')

$network_metadata = hiera_hash('network_metadata')
$keystone_hash    = hiera_hash('keystone', {})
# enabled by default
$use_keystone = pick($keystone_hash['enabled'], true)
$public_ssl_hash = hiera('public_ssl')
$ssl_hash = hiera_hash('use_ssl', {})

#todo(sv): change to 'keystone' as soon as keystone as node-role was ready
$keystones_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller']), 'keystone/api')

if ($use_keystone) {
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
    public_ssl          => $public_ssl_hash['services'] or try_get_value($ssl_hash, 'keystone_public', false),
    public_ssl_path     => "/var/lib/astute/haproxy/public_keystone.pem",
    internal_ssl        => try_get_value($ssl_hash, 'keystone_internal', false),
    internal_ssl_path   => "/var/lib/astute/haproxy/internal_keystone.pem",
    admin_ssl           => try_get_value($ssl_hash, 'keystone_admin', false),
    admin_ssl_path      => "/var/lib/astute/haproxy/admin_keystone.pem",
  }
}
