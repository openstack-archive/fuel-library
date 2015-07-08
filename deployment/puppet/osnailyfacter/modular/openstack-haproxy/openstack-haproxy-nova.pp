notice('MODULAR: openstack-haproxy-nova.pp')

$nova_hash = hiera_hash('nova', {})
# enabled by default
$use_nova = pick($nova_hash['enabled']

if ($use_nova) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
  hiera('controllers', undef))
  $server_names        = pick(hiera_array('nova_names', undef),
  filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('nova_ipaddresses', undef),
  filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')


  # configure nova ha proxy
  class { '::openstack::ha::nova':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
