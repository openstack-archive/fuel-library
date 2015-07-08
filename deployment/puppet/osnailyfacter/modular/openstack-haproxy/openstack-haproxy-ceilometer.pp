notice('MODULAR: openstack-haproxy-ceilometer.pp')

$ceilometer_hash     = hiera_hash('ceilometer',{})
# NOT enabled by default
$use_ceilometer      = pick($ceilometer_hash['enabled'], false)

if ($use_ceilometer) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick(hiera_array('ceilometer_names', undef),
                              filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('ceilometer_ipaddresses', undef),
                              filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure ceilometer ha proxy
  class { '::openstack::haproxy::ceilometer':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
