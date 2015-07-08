notice('MODULAR: openstack-haproxy-horizon.pp')

$network_metadata = hiera_hash('network_metadata')
$horizon_hash = hiera_hash('horizon', {})
# enabled by default
$use_horizon = pick($horizon_hash['enabled'], true)
$public_ssl_hash = hiera('public_ssl')

$horizon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('horizon_nodes'), 'horizon')
if ($use_horizon) {
  $server_names        = hiera_array('horizon_names', keys($horizon_address_map))
  $ipaddresses         = hiera_array('horizon_ipaddresses', values($horizon_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure horizon ha proxy
  class { '::openstack::ha::horizon':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    use_ssl             => $public_ssl_hash['horizon'],
  }
}
