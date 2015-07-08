notice('MODULAR: openstack-haproxy-murano.pp')

$murano_hash         = hiera_hash('murano',{})
# NOT enabled by default
$use_murano          = pick($murano_hash['enabled'], false)

if ($use_murano) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick(hiera_array('murano_names', undef),
                              filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('murano_ipaddresses', undef),
                              filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure murano ha proxy
  class { '::openstack::ha::murano':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
