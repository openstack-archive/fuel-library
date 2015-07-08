notice('MODULAR: openstack-haproxy-sahara.pp')

$sahara_hash     = hiera_hash('sahara',{})
# NOT enabled by default
$use_sahara      = pick($sahara_hash['enabled'], false)

if ($use_sahara) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick(hiera_array('sahara_names', undef),
                              filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('sahara_ipaddresses', undef),
                              filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure sahara ha proxy
  class { '::openstack::ha::sahara':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
