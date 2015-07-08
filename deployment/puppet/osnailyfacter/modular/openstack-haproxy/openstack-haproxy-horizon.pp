notice('MODULAR: openstack-haproxy-horizon.pp')

$horizon_hash = hiera_hash('horizon', {})
# enabled by default
$use_horizon  = pick($horizon_hash['enabled'], true)

if ($use_horizon) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick(hiera_array('horizon_names', undef),
                              filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('horizon_ipaddresses', undef),
                              filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  $horizon_use_ssl     = hiera('horizon_use_ssl', false)

  # configure horizon ha proxy
  class { '::openstack::ha::horizon':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    use_ssl             => $horizon_use_ssl,
  }
}
