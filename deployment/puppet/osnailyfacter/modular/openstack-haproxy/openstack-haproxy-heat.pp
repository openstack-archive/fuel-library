notice('MODULAR: openstack-haproxy-heat.pp')

$heat_hash = hiera_hash('heat', {})
# enabled by default
$use_heat  = pick($heat_hash['enabled'], true)

if ($use_heat) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick(hiera_array('heat_names', undef),
                              filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('heat_ipaddresses', undef),
                              filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

# configure heat ha proxy
  class { '::openstack::ha::heat':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
