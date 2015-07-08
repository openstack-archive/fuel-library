notice('MODULAR: openstack-haproxy-glance.pp')

$network_metadata = hiera_hash('network_metadata')
$glance_hash      = hiera_hash('glance', {})
# enabled by default
$use_glance       = pick($glance_hash['enabled'], true)
$public_ssl_hash  = hiera('public_ssl')


#todo(sv): change to 'glance' as soon as glance as node-role was ready
$glances_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller']), 'glance/api')

if ($use_glance) {
  $server_names        = hiera_array('glance_names', keys($glances_address_map))
  $ipaddresses         = hiera_array('glance_ipaddresses', values($glances_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  class { '::openstack::ha::glance':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl_hash['services'],
  }
}
