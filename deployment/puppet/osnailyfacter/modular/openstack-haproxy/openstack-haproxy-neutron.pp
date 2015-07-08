notice('MODULAR: openstack-haproxy-neutron.pp')

# NOT enabled by default
$use_neutron         = hiera('use_neutron', false)

if ($use_neutron) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick(hiera_array('neutron_names', undef),
                              filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('neutron_ipaddresses', undef),
                              filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure neutron ha proxy
  class { '::openstack::ha::neutron':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
