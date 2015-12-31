notice('MODULAR: openstack-haproxy-nova.pp')

$nova_hash            = hiera_hash('nova', {})
# enabled by default
$use_nova             = pick($nova_hash['enabled'], true)
$public_ssl_hash      = hiera('public_ssl')
$ssl_hash             = hiera_hash('use_ssl', {})

$public_ssl           = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'usage', false)
$public_ssl_path      = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'path', [''])

$internal_ssl         = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'usage', false)
$internal_ssl_path    = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'path', [''])

$nova_api_address_map = get_node_to_ipaddr_map_by_network_role(hiera('nova_api_nodes'), 'nova/api')

$external_lb          = hiera('external_lb', false)

if ($use_nova and !$external_lb) {
  $server_names        = hiera_array('nova_names', keys($nova_api_address_map))
  $ipaddresses         = hiera_array('nova_ipaddresses', values($nova_api_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')


  # configure nova ha proxy
  class { '::openstack::ha::nova':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl,
    public_ssl_path     => $public_ssl_path,
    internal_ssl        => $internal_ssl,
    internal_ssl_path   => $internal_ssl_path,
  }
}
