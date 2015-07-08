notice('MODULAR: openstack-haproxy-keystone.pp')

$haproxy_hash = hiera_hash('haproxy_hash')
$keystone_hash = hiera_hash('keystone', {})
# enabled by default
$use_keystone = pick($keystone_hash['enabled'], true)

if ($use_keystone) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick($haproxy_hash['nodes_ips'],
                              filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick($haproxy_hash['nodes_names'],
                              filter_hash($haproxy_nodes, 'internal_address'))

  $public_virtual_ip   = pick(hiera('public_service_endpoint', undef), hiera('management_vip'))
  $internal_virtual_ip = pick(hiera('service_endpoint', undef), hiera('management_vip'))


  # configure keystone ha proxy
  class { '::openstack::ha::keystone':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
