notice('MODULAR: openstack-haproxy-nova.pp')

$nova_hash = hiera_hash('nova', {})
# enabled by default
$use_nova = pick($nova_hash['enabled'], true)

$controllers              = hiera('controllers')
$controllers_server_names = filter_hash($controllers, 'name')
$controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

if ($use_nova) {
  $server_names        = pick(hiera_array('nova_names', undef),
                              $controllers_server_names)
  $ipaddresses         = pick(hiera_array('nova_ipaddresses', undef),
                              $controllers_ipaddresses)
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')


  # configure nova ha proxy
  class { '::openstack::ha::nova':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
