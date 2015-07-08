notice('MODULAR: openstack-haproxy-cinder.pp')

$cinder_hash = hiera_hash('cinder', {})
# enabled by default
$use_cinder  = pick($cinder_hash['enabled'], true)

if ($use_cinder) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
  hiera('controllers', undef))
  $server_names        = pick(hiera_array('cinder_names', undef),
  filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('cinder_ipaddresses', undef),
  filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure cinder ha proxy
  class { '::openstack::ha::cinder':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
