notice('MODULAR: openstack-haproxy-ironic.pp')

$ironic_hash         = hiera_hash('ironic',{})
# NOT enabled by default
$use_ironic          = pick($ironic_hash['enabled'], false)

if ($use_ironic) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick(hiera_array('ironic_names', undef),
                              filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('ironic_ipaddresses', undef),
                              filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')
  $baremetal_virtual_ip = hiera('baremetal_vip')

  # configure ironic ha proxy
  class { '::openstack::ha::ironic':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    baremetal_virtual_ip => $baremetal_virtual_ip,
    server_names        => $server_names,
  }
}
