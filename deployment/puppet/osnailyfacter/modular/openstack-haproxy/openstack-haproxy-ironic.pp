notice('MODULAR: openstack-haproxy-ironic.pp')

$network_metadata = hiera_hash('network_metadata')
$public_ssl_hash  = hiera('public_ssl')
$ironic_hash      = hiera_hash('ironic', {})
$use_ironic       = pick($ironic_hash['enabled'], false)

$ironic_address_map = get_node_to_ipaddr_map_by_network_role(hiera('ironic_api_nodes'), 'ironic/api')

if ($use_ironic) {
  $server_names         = hiera_array('ironic_server_names', keys($ironic_address_map))
  $ipaddresses          = hiera_array('ironic_ipaddresses', values($ironic_address_map))
  $public_virtual_ip    = hiera('public_vip')
  $internal_virtual_ip  = hiera('management_vip')
  $baremetal_virtual_ip = $network_metadata['vips']['baremetal']['ipaddr']

  class { '::openstack::ha::ironic':
    internal_virtual_ip  => $internal_virtual_ip,
    ipaddresses          => $ipaddresses,
    public_virtual_ip    => $public_virtual_ip,
    server_names         => $server_names,
    public_ssl           => $public_ssl_hash['services'],
    baremetal_virtual_ip => $baremetal_virtual_ip,
  }
}
