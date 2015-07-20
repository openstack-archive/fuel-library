notice('MODULAR: openstack-haproxy-ironic.pp')

$ironic_hash         = hiera_hash('ironic',{})
# NOT enabled by default
$use_ironic          = pick($ironic_hash['enabled'], false)
$public_ssl_hash     = hiera('public_ssl')

$controllers              = hiera('controllers')
$controllers_server_names = filter_hash($controllers, 'name')
$controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

if ($use_ironic) {
  $server_names         = pick(hiera_array('ironic_names', undef),
                               $controllers_server_names)
  $ipaddresses          = pick(hiera_array('ironic_ipaddresses', undef),
                               $controllers_ipaddresses)
  $public_virtual_ip    = hiera('public_vip')
  $internal_virtual_ip  = hiera('management_vip')
  $baremetal_virtual_ip = hiera('baremetal_vip')

# configure ironic ha proxy
  class { '::openstack::ha::ironic':
    internal_virtual_ip  => $internal_virtual_ip,
    ipaddresses          => $ipaddresses,
    public_virtual_ip    => $public_virtual_ip,
    baremetal_virtual_ip => $baremetal_virtual_ip,
    server_names         => $server_names,
    public_ssl           => $public_ssl_hash['services'],
  }
}
